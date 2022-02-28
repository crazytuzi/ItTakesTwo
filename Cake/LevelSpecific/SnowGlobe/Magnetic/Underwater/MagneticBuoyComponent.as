import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Peanuts.Audio.HazeAudioEffects.DopplerDataComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;

class UMagneticBuoyComponent : UMagneticComponent
{
	// These are initialized in MagneticBuoy's actor construction script
	float PlayerImpulse;
	float MinValidPlayerDistance;

	UDopplerDataComponent DopplerDataComp;
	int32 InteractingPlayerCount = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DopplerDataComp = UDopplerDataComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter PlayerCharacter, FHazeQueriedActivationPoint& Query)const override
	{
		if(GetDistance(EHazeActivationPointDistanceType::Selectable) <= PlayerCharacter.GetDistanceTo(Owner))
			return EHazeActivationPointStatusType::Invalid;

		if(!USnowGlobeSwimmingComponent::Get(PlayerCharacter).bIsUnderwater)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		if(Owner.GetDistanceTo(PlayerCharacter) < MinValidPlayerDistance)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		return Super::SetupActivationStatus(PlayerCharacter, Query);
	}
}