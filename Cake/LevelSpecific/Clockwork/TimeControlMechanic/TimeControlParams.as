
enum ETimeDilationSlowdownExhaustedType
{
	Default,
	Active,
	Inactive
};


struct FTimeDilationTargetStep
{
	float Target = 1;
	float DelayTimeLeft = 0;
}

namespace TimeControlCapabilityTags
{
	const FName TimeDiliationCapability = n"TimeDiliationCapability";
	const FName TimeControlCapability = n"TimeControlCapability";
	const FName FindTimeObjectsCapability = n"FindTimeObjectsCapability";
	const FName TimeSequenceCapability = n"TimeSequenceCapability";
}
