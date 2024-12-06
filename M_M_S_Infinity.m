% Configuration
clear; % Clear all variables from the workspace
clc; % Clear the command window
close all; % Close all open figure windows
rng(11); % Random generator seed for reproducibility

% Parameters
lambda = 10; % Arrival rate (lambda calls per unit time)
mu = 2; % Service rate (mu calls per unit time)
S_range = 1:1:20; % Number of servers (range of them)
total_time = 100; % Total time for the simulation (total unit time)

% Storage
delay_probabilities = zeros(size(S_range)); % All simulated delay probabilities
theoretical_delay_probabilities = zeros(size(S_range)); % All theoretical delay probabilities
utilization = zeros(size(S_range)); % All simulated server utilization rates
theoretical_utilization = zeros(size(S_range)); % All theoretical server utilization rates

% Simulations for different values of S
for idx = 1:length(S_range)
    S = S_range(idx);  % Current S value
    
    % Storage
    time_in_system = []; % Unit time at specific event (index is event)
    calls_in_system = []; % Number of calls at specific event (index is event)

    % Initialization
    current_time = 0; % Current system time
    time_busy = 0; % Total time servers are busy
    num_calls = 0; % Current number of calls in system
    num_queue_calls = 0; % Current number of calls in queue
    num_offered_calls = 0; % Number of offered calls
    num_delayed_calls = 0; % Number of delayed calls
    next_arrival_time = NaN; % Next arrival time
    scheduled_departure_times = []; % Scheduled departures (not in order)
   
    % Simulation
    while current_time < total_time
    
        % Set the arrival time for the first call
        if (isnan(next_arrival_time))
            inter_arrival_time = exprnd(1 / lambda);
            next_arrival_time = current_time + inter_arrival_time;

            % Log event
            time_in_system(end + 1) = current_time;
            calls_in_system(end + 1) = num_calls;
            continue;
        end
    
        % Determine if the next event is an arrival or a departure
        if isempty(scheduled_departure_times) || next_arrival_time <= min(scheduled_departure_times)
    
            % Arrival event
            current_time = next_arrival_time;
            next_arrival_time = NaN; % Remove processed arrival
    
            % Increase the offered calls count
            num_offered_calls = num_offered_calls + 1;

            % Determine if there are available servers
            if num_calls < S
    
                % Server is available
                num_calls = num_calls + 1;
        
                % Schedule the departure time for this call
                service_time = exprnd(1 / mu);
                scheduled_departure_times(end + 1) = current_time + service_time;

                % Update server busy time
                time_busy = time_busy + service_time;
            else
                
                % All servers are busy, add the call to the queue
                num_queue_calls = num_queue_calls + 1;
                num_delayed_calls = num_delayed_calls + 1;
            end
    
            % Set the arrival time for the next call
            inter_arrival_time = exprnd(1 / lambda);
            next_arrival_time = current_time + inter_arrival_time;
        else
    
            % Departure event
            [departure_time, departure_index] = min(scheduled_departure_times);
            current_time = departure_time;
            scheduled_departure_times(departure_index) = []; % Remove processed departure

            % Check if there are calls in the queue
            if num_queue_calls > 0
                % Move a call from the queue to a server
                num_queue_calls = num_queue_calls - 1;
        
                % Schedule the departure time for this call
                service_time = exprnd(1 / mu);
                scheduled_departure_times(end + 1) = current_time + service_time;
        
                % Update server busy time
                time_busy = time_busy + service_time;
            else
                num_calls = num_calls - 1;
            end
        end
    
        % Log event
        time_in_system(end + 1) = current_time;
        calls_in_system(end + 1) = num_calls + num_queue_calls;
    end

    % Simulated delay probability for this S
    delay_probabilities(idx) = num_delayed_calls / num_offered_calls;

    % Theoretical delay probability using Erlang C formula
    numerator = ((lambda / mu)^S / factorial(S)) * (S / (S - (lambda / mu)));
    denominator = 0;
    for k = 0:S-1
    denominator = denominator + (lambda / mu)^k / factorial(k);
    end
    denominator = denominator + ((lambda / mu)^S / factorial(S)) * (S / (S - (lambda / mu)));
    theoretical_delay_probabilities(idx) = numerator / denominator;

    % Simulated server utilization
    utilization(idx) = time_busy / (total_time * S);

    % Theoretical server utilization
    theoretical_utilization(idx) = min(lambda / (S*mu), 1);


    % Only done for the last simulation
    if idx == length(S_range)

        % Weighted average number of calls in the system
        sum_calls = 0;
        for i = 1:length(time_in_system)-1
            % Duration of the current event interval
            interval_duration = time_in_system(i+1) - time_in_system(i);
            
            % Weighted sum
            sum_calls = sum_calls + calls_in_system(i) * interval_duration;
        end
        average_calls = sum_calls / total_time;
        
        % For probability distribution of number of calls if calls weren't dropped in the system
        [n, edges] = histcounts(calls_in_system, 'Normalization', 'probability');

        % Screen size for positioning
        screen_size = get(0, 'ScreenSize');
        figure_width = screen_size(3) / 3;
        figure_height = screen_size(4) / 2;


        % Visualization: number of calls in the system over time
        figure(1);
        set(gcf, 'Color', [0.15, 0.15, 0.15], 'Position', [0, screen_size(4)-figure_height-200, figure_width, figure_height]);
        
        stairs(time_in_system, calls_in_system, 'LineWidth', 1, 'Color', [0.9, 0.6, 0.2]);
        hold on;
        
        yline(average_calls, 'r--', 'LineWidth', 2);

        yline(S, 'g--', 'LineWidth', 1);
        
        title('Number of Calls in M/M/S/∞ System over Time', 'Color', 'w', 'FontSize', 14);
        xlabel('Time', 'Color', 'w', 'FontSize', 12);
        ylabel('Number of Calls', 'Color', 'w', 'FontSize', 12);
        
        grid on;
        set(gca, 'GridColor', 'w', 'GridAlpha', 0.7, 'Color', [0.05, 0.05, 0.05], 'XColor', 'w', 'YColor', 'w');
        
        legend({'Calls in System', ['Average = ' num2str(average_calls, '%.2f')], 'System Capacity'}, 'Location', 'Best', 'TextColor', 'w');
        
        axis equal;
        

        % Visualization: probability distribution of calls in the system
        figure(2);
        set(gcf, 'Color', [0.15, 0.15, 0.15], 'Position', [2 * figure_width, screen_size(4)-figure_height-200, figure_width, figure_height]);
        
        bar(edges(1:end-1) + diff(edges)/2, n, 'FaceColor', [0.9, 0.6, 0.2], 'EdgeColor', 'none', 'FaceAlpha', 0.8);
        hold on;
        
        title('Probability Distribution of Calls in M/M/S/∞ System', 'Color', 'w', 'FontSize', 14);
        xlabel('Number of Calls', 'Color', 'w', 'FontSize', 12);
        ylabel('Probability', 'Color', 'w', 'FontSize', 12);
        
        grid on;
        set(gca, 'GridColor', 'w', 'GridAlpha', 0.7, 'Color', [0.05, 0.05, 0.05], 'XColor', 'w', 'YColor', 'w');
        
        legend({'Calls Distribution'}, 'Location', 'Best', 'TextColor', 'w');
        
        axis padded;
    end
end

% Preprocess theoretical delay probabilities to handle NaN and values > 1
theoretical_delay_probabilities(isnan(theoretical_delay_probabilities) | theoretical_delay_probabilities > 1) = 1;

% Calculate trend line of simulated delay probability using cubic smoothing spline
spline_fit = csaps(S_range, delay_probabilities, 0.05);
fitted_delay_probabilities = fnval(spline_fit, S_range);
fitted_delay_probabilities = max(min(fitted_delay_probabilities, 1), 0);
fitted_qos = 1 - fitted_delay_probabilities;

% Calculate trend line of simulated utilization using cubic smoothing spline
u_spline_fit = csaps(S_range, utilization, 0.05);
fitted_utilization = fnval(u_spline_fit, S_range);
fitted_utilization = max(min(fitted_utilization, 1), 0);

% Screen size for positioning
screen_size = get(0, 'ScreenSize');
figure_width = screen_size(3) / 3;
figure_height = screen_size(4) - 200;


% Visualization: probability of delay vs capacity and server utilization vs capacity
figure(3);
set(gcf, 'Color', [0.15, 0.15, 0.15], 'Position', [figure_width, 100, figure_width, figure_height]);

% Probability of delay vs capacity
subplot(2, 1, 1);
plot(S_range, delay_probabilities, 'o', 'MarkerSize', 3, 'LineWidth', 1, 'Color', [0.9, 0.6, 0.2]);
hold on;

plot(S_range, fitted_delay_probabilities, 'r--', 'LineWidth', 2);
 
plot(S_range, theoretical_delay_probabilities, '--', 'LineWidth', 1, 'Color', [0.0, 1.0, 1.0]);

plot(S_range, fitted_qos, 'g--', 'LineWidth', 1);

title('Probability of Delay in M/M/S/∞ System vs Capacity (S)', 'Color', 'w', 'FontSize', 14);
xlabel('Capacity (S)', 'Color', 'w', 'FontSize', 12);
ylabel('Probability of Delay', 'Color', 'w', 'FontSize', 12);

grid on;
set(gca, 'GridColor', 'w', 'GridAlpha', 0.7, 'Color', [0.05, 0.05, 0.05], 'XColor', 'w', 'YColor', 'w');

legend({'Simulated Delay Probability', 'Trend of Simulated Delay Probability', 'Theoretical Delay Probability', 'QoS'}, 'Location', 'Best', 'TextColor', 'w');

ylim([0 1]);
axis normal;

% Server utilization vs capacity
subplot(2, 1, 2);
plot(S_range, utilization * 100, 'o', 'MarkerSize', 3, 'LineWidth', 1, 'Color', [0.9, 0.6, 0.2]);
hold on;

plot(S_range, fitted_utilization * 100, 'r--', 'LineWidth', 2);

plot(S_range, theoretical_utilization * 100, '--', 'LineWidth', 1, 'Color', [0.0, 1.0, 1.0]);

title('Server Utilization in M/M/S/∞ System vs Capacity (S)', 'Color', 'w', 'FontSize', 14);
xlabel('Capacity (S)', 'Color', 'w', 'FontSize', 12);
ylabel('Server Utilization (%)', 'Color', 'w', 'FontSize', 12);

grid on;
set(gca, 'GridColor', 'w', 'GridAlpha', 0.7, 'Color', [0.05, 0.05, 0.05], 'XColor', 'w', 'YColor', 'w');

legend({'Simulated Utilization', 'Trend of Simulated Utilization', 'Theoretical Utilization'}, 'Location', 'Best', 'TextColor', 'w');

ylim([0 100]);
axis normal;