import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

UCLASS(Abstract)
class UPlantMovementCapability : UCharacterMovementCapability
{
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
        CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
		ActiveMovementSettings = UMovementSettings::GetSettings(Owner);
 		devEnsure(CheckIfTickGroupIsMovementTickGroup(TickGroup), "TickGroup is not set Correctly on " + Name +  ". all Movement capabilities has to be in a movement Tickgroup. If you are unsure what group to put your capability in you can ask Simon or Tyko.");
	}
}