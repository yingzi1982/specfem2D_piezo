function [env]=trace2envelope(signal,np)

t = signal(:,1);
t = t-t(1);

s = signal(:,2:end);

env_positive = abs(hilbert(s));
env_negative = abs(hilbert(-s));
env = [env_positive;flipud(-env_negative)];

%env = env/max(abs(env(:)));

t = [t;flipud(t)];
env =[t env];

resample_rate = floor(rows(s)/np);
env = env(1:resample_rate:end,:);

end
