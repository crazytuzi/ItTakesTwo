import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Peanuts.Audio.HazeAudioEffects.DopplerDataComponent;

UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
class UMagneticIceSkatingBoostGateComponent : UMagneticComponent
{
	UPROPERTY()
	float ActivateConeAngle;

	UPROPERTY(NotVisible)
	UDopplerDataComponent DopplerDataComp;

	default bUseGenericMagnetAnimation = false;

	bool IsValidToUseBy(AHazePlayerCharacter Player) const
	{
		FVector PlayerToPoint = WorldLocation - Player.ActorLocation;
		PlayerToPoint.Normalize();

		bool bPlayerIsFacingPoint = PlayerToPoint.DotProduct(Player.ActorForwardVector) > 0.f;

		if (!bPlayerIsFacingPoint)
			return false;

		float Angle = Math::DotToDegrees(PlayerToPoint.DotProduct(ForwardVector));
		if (Angle > ActivateConeAngle * 0.5f)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const override
	{
		EHazeActivationPointStatusType Status = Super::SetupActivationStatus(Player, Query);
		if (Status != EHazeActivationPointStatusType::Valid)
			return Status;

		// We only allow one active point at a time
		UHazeActivationPoint ActivePoint = Player.GetActivePoint();
		if (ActivePoint != nullptr && ActivePoint != this)
			return EHazeActivationPointStatusType::Invalid;

		if (!IsValidToUseBy(Player))
			return EHazeActivationPointStatusType::InvalidAndHidden;

		return Status;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DopplerDataComp = UDopplerDataComponent::Get(Owner);
	}
}