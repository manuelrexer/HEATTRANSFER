function [systematic uncertainty] = getSystematicUncertatinty(pID)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%% Loading
% data=tbd(pID);

%% Extracting
offset =;
sensitivity=;

lin=data.hasSystemCapability.SensorCapability.hasProperty.LinearityUncertainty.value.literal;
hys=data.hasSystemCapability.SensorCapability.hasProperty.HysteresisUncertainty.value.literal;
end