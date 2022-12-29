function [image]=trace2image(trace,nt,range)

resample = floor(rows(trace)/nt);

t = trace(:,1);
t = t(1:resample:end);

trace = trace(:,2:end);

TRACE = abs(hilbert(trace));
%TRACE = TRACE/max(abs(TRACE(:)));
%TRACE = TRACE./max(abs(TRACE));

TRACE = TRACE(1:resample:end,:);


[RANGE T] = meshgrid(range,t);

image = reshape(TRACE,[],1);
RANGE = reshape(RANGE(:,:),[],1);
T = reshape(T(:,:),[],1);

image = [RANGE T image];
end
