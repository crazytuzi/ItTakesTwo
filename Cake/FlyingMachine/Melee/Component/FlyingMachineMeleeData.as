
const FName ControlActivationName = n"ControlActivationData";

struct FMeleePendingControlData
{
	ULocomotionFeatureMeleeBase Feature = nullptr;
	EHazeMeleeActionInputType ActionType = EHazeMeleeActionInputType::None;

	void Consume(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(ControlActivationName, Feature);
		ActivationParams.AddNumber(ControlActivationName, int(ActionType));
		Clear();
	}

	void Receive(FCapabilityActivationParams ActivationParams)
	{
		Feature = Cast<ULocomotionFeatureMeleeBase>(ActivationParams.GetObject(ControlActivationName));
		ActionType = EHazeMeleeActionInputType(ActivationParams.GetNumber(ControlActivationName));
	}

	void Clear()
	{
		Feature = nullptr;
		ActionType = EHazeMeleeActionInputType::None;
	}
}