import Peanuts.Audio.Reflection.ReflectionTraceManager;
import Peanuts.Audio.Reflection.ReflectionTraceCapability;

UReflectionTraceManager GetReflectionTraceManager()
{
	return UReflectionTraceManager::GetOrCreate(Game::GetMay());
}

void Subscribe(UReflectionTraceCapability Capability)
{
	auto Manager = GetReflectionTraceManager();
	Manager.Subscribe(Capability);	
}

void Unsubscribe(UReflectionTraceCapability Capability)
{
	auto Manager = GetReflectionTraceManager();
	Manager.Unsubscribe(Capability);
}

bool SetDelayParameterRanges(FReflectionTraceValues& TraceDataValues, EEnvironmentType Environment)
{
	if(Environment == EEnvironmentType::Swtc_Environment_None)
		return false;

	switch(Environment)
	{
		case EEnvironmentType::Swtc_Environment_Exterior_Canyon:
			TraceDataValues.MinDelayVolume = -32.f;
			TraceDataValues.MaxDelayVolume = -10.f;
			TraceDataValues.ReverbSendLevel = 6.f;
			TraceDataValues.MinDelayTime = 0.4f;
			TraceDataValues.MaxDelayTime = 0.05f;
			TraceDataValues.MinHighShelfFilterFreq = 1000.f;
			TraceDataValues.MaxHighShelfFilterFreq = 10000.f;
			TraceDataValues.MinLowShelfFilterFreq = 500.f;
			TraceDataValues.MaxLowShelfFilterFreq = 100.f;
			TraceDataValues.PeakFilterFreq = 400.f;
			TraceDataValues.PeakFilterGain = 6.f;
			TraceDataValues.MinFeedback = 30.f;
			TraceDataValues.MaxFeedback = 30.f;
			TraceDataValues.SoftMaterialFreqMultiplier = 0.5f;
			TraceDataValues.HardMaterialFreqMultiplier = 1.f;
			TraceDataValues.MinTraceDistance = 200.f;
			TraceDataValues.MaxTraceDistance = 5000.f;
			
			return true;

		case EEnvironmentType::Swtc_Environment_Exterior_Field:
			TraceDataValues.MinDelayVolume = -34.f;
			TraceDataValues.MaxDelayVolume = -12.f;
			TraceDataValues.ReverbSendLevel = 0.f;
			TraceDataValues.MinDelayTime = 1.25f;
			TraceDataValues.MaxDelayTime = 0.07f;
			TraceDataValues.MinHighShelfFilterFreq = 500.f;
			TraceDataValues.MaxHighShelfFilterFreq = 8000.f;
			TraceDataValues.MinLowShelfFilterFreq = 300.f;
			TraceDataValues.MaxLowShelfFilterFreq = 100.f;
			TraceDataValues.PeakFilterFreq = 400.f;
			TraceDataValues.PeakFilterGain = 0.f;
			TraceDataValues.MinFeedback = 35.f;
			TraceDataValues.MaxFeedback = 5.f;
			TraceDataValues.SoftMaterialFreqMultiplier = 1.f;
			TraceDataValues.HardMaterialFreqMultiplier = 1.f;
			TraceDataValues.MinTraceDistance = 200.f;
			TraceDataValues.MaxTraceDistance = 10000.f;

			return true;

		case EEnvironmentType::Swtc_Environment_Exterior_Forest:
			TraceDataValues.MinDelayVolume = -32.f;
			TraceDataValues.MaxDelayVolume = -7.f;
			TraceDataValues.ReverbSendLevel = 6.f;
			TraceDataValues.MinDelayTime = 0.25f;
			TraceDataValues.MaxDelayTime = 0.05f;
			TraceDataValues.MinHighShelfFilterFreq = 2000.f;
			TraceDataValues.MaxHighShelfFilterFreq = 12000.f;
			TraceDataValues.MinLowShelfFilterFreq = 500.f;
			TraceDataValues.MaxLowShelfFilterFreq = 100.f;
			TraceDataValues.PeakFilterFreq = 400.f;
			TraceDataValues.PeakFilterGain = 0.f;
			TraceDataValues.MinFeedback = 40.f;
			TraceDataValues.MaxFeedback = 25.f;
			TraceDataValues.SoftMaterialFreqMultiplier = 0.5f;
			TraceDataValues.HardMaterialFreqMultiplier = 1.f;
			TraceDataValues.MinTraceDistance = 200.f;
			TraceDataValues.MaxTraceDistance = 5000.f;

			return true;

		case EEnvironmentType::Swtc_Environment_Interior_Small:
			TraceDataValues.MinDelayVolume = -32.f;
			TraceDataValues.MaxDelayVolume = -3.f;
			TraceDataValues.ReverbSendLevel = 0.f;
			TraceDataValues.MinDelayTime = 0.2f;
			TraceDataValues.MaxDelayTime = 0.05f;
			TraceDataValues.MinHighShelfFilterFreq = 5000.f;
			TraceDataValues.MaxHighShelfFilterFreq = 15000.f;
			TraceDataValues.MinLowShelfFilterFreq = 500.f;
			TraceDataValues.MaxLowShelfFilterFreq = 100.f;
			TraceDataValues.PeakFilterFreq = 400.f;
			TraceDataValues.PeakFilterGain = 0.f;
			TraceDataValues.MinFeedback = 45.f;
			TraceDataValues.MaxFeedback = 15.f;
			TraceDataValues.SoftMaterialFreqMultiplier = 1.f;
			TraceDataValues.HardMaterialFreqMultiplier = 1.f;
			TraceDataValues.MinTraceDistance = 100.f;
			TraceDataValues.MaxTraceDistance = 2500.f;

			return true;

		case EEnvironmentType::Swtc_Environment_Interior_Large:
			TraceDataValues.MinDelayVolume = -30.f;
			TraceDataValues.MaxDelayVolume = -10.f;
			TraceDataValues.ReverbSendLevel = 6.f;
			TraceDataValues.MinDelayTime = 0.4f;
			TraceDataValues.MaxDelayTime = 0.05f;
			TraceDataValues.MinHighShelfFilterFreq = 2000.f;
			TraceDataValues.MaxHighShelfFilterFreq = 12000.f;
			TraceDataValues.MinLowShelfFilterFreq = 300.f;
			TraceDataValues.MaxLowShelfFilterFreq = 100.f;
			TraceDataValues.PeakFilterFreq = 400.f;
			TraceDataValues.PeakFilterGain = 0.f;
			TraceDataValues.MinFeedback = 30.f;
			TraceDataValues.MaxFeedback = 1.f;
			TraceDataValues.SoftMaterialFreqMultiplier = 0.5f;
			TraceDataValues.HardMaterialFreqMultiplier = 1.f;
			TraceDataValues.MinTraceDistance = 200.f;
			TraceDataValues.MaxTraceDistance = 4500.f;

			return true;

		case EEnvironmentType::Swtc_Environment_Interior_XLarge:
			TraceDataValues.MinDelayVolume = -36.f;
			TraceDataValues.MaxDelayVolume = -10.f;
			TraceDataValues.ReverbSendLevel = 0.f;
			TraceDataValues.MinDelayTime = 1.25f;
			TraceDataValues.MaxDelayTime = 0.15f;
			TraceDataValues.MinHighShelfFilterFreq = 2000.f;
			TraceDataValues.MaxHighShelfFilterFreq = 12000.f;
			TraceDataValues.MinLowShelfFilterFreq = 300.f;
			TraceDataValues.MaxLowShelfFilterFreq = 100.f;
			TraceDataValues.PeakFilterFreq = 400.f;
			TraceDataValues.PeakFilterGain = 0.f;
			TraceDataValues.MinFeedback = 50.f;
			TraceDataValues.MaxFeedback = 20.f;
			TraceDataValues.SoftMaterialFreqMultiplier = 1.f;
			TraceDataValues.HardMaterialFreqMultiplier = 1.f;
			TraceDataValues.MinTraceDistance = 500.f;
			TraceDataValues.MaxTraceDistance = 15000.f;

			return true;

		case EEnvironmentType::Swtc_Environment_Tunnel_Small:
			TraceDataValues.MinDelayVolume = -32.f;
			TraceDataValues.MaxDelayVolume = -3.f;
			TraceDataValues.ReverbSendLevel = 0.f;
			TraceDataValues.MinDelayTime = 0.15f;
			TraceDataValues.MaxDelayTime = 0.05f;
			TraceDataValues.MinHighShelfFilterFreq = 5000.f;
			TraceDataValues.MaxHighShelfFilterFreq = 15000.f;
			TraceDataValues.MinLowShelfFilterFreq = 500.f;
			TraceDataValues.MaxLowShelfFilterFreq = 100.f;
			TraceDataValues.PeakFilterFreq = 400.f;
			TraceDataValues.PeakFilterGain = 3.f;
			TraceDataValues.MinFeedback = 50.f;
			TraceDataValues.MaxFeedback = 20.f;
			TraceDataValues.SoftMaterialFreqMultiplier = 1.f;
			TraceDataValues.HardMaterialFreqMultiplier = 1.f;
			TraceDataValues.MinTraceDistance = 100.f;
			TraceDataValues.MaxTraceDistance = 2500.f;

			return true;

		case EEnvironmentType::Swtc_Environment_Tunnel_Large:
			TraceDataValues.MinDelayVolume = -32.f;
			TraceDataValues.MaxDelayVolume = -10.f;
			TraceDataValues.ReverbSendLevel = -6.f;
			TraceDataValues.MinDelayTime = 0.3f;
			TraceDataValues.MaxDelayTime = 0.05f;
			TraceDataValues.MinHighShelfFilterFreq = 4000.f;
			TraceDataValues.MaxHighShelfFilterFreq = 15000.f;
			TraceDataValues.MinLowShelfFilterFreq = 500.f;
			TraceDataValues.MaxLowShelfFilterFreq = 100.f;
			TraceDataValues.PeakFilterFreq = 400.f;
			TraceDataValues.PeakFilterGain = 6.f;
			TraceDataValues.MinFeedback = 50.f;
			TraceDataValues.MaxFeedback = 35.f;
			TraceDataValues.SoftMaterialFreqMultiplier = 0.5f;
			TraceDataValues.HardMaterialFreqMultiplier = 1.f;
			TraceDataValues.MinTraceDistance = 100.f;
			TraceDataValues.MaxTraceDistance = 3000.f;

			return true;

		default:
			break;
	}

	return true;
}
