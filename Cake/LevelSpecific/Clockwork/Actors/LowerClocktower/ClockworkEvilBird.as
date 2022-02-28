import Vino.Movement.Swinging.SwingComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;

class AClockworkEvilBird : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSkeletalMeshComponentBase Bird;

	UPROPERTY(DefaultComponent)
	USwingPointComponent BeakSwingPoint;
	default BeakSwingPoint.RelativeLocation = FVector(256, 0, 138);
	default BeakSwingPoint.ValidationType = EHazeActivationPointActivatorType::May;
	default BeakSwingPoint.InitializeDistance(EHazeActivationPointDistanceType::Visible, 10000.f);
	default BeakSwingPoint.InitializeDistance(EHazeActivationPointDistanceType::Targetable, 6000.f);
	default BeakSwingPoint.InitializeDistance(EHazeActivationPointDistanceType::Selectable, 3000.f);

	UPROPERTY()
	FOnSwingPointAttached OnBeakPointAttached;

	UPROPERTY()
	FOnSwingPointDetached OnBeakPointDetached;

	ALevelSequenceActor IsCarryingCodyLevelSequeunce;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BeakSwingPoint.OnSwingPointAttached.AddUFunction(this, n"SwingPointAttached");
		BeakSwingPoint.OnSwingPointDetached.AddUFunction(this, n"SwingPointDetached");

		AddCapability(n"ClockworkEvilBirdTimeDilationCapability");
	}

	UFUNCTION()
	void OnCodyPickedUp(ALevelSequenceActor FromLevelSequeunce)
	{
		IsCarryingCodyLevelSequeunce = FromLevelSequeunce;
	}

	UFUNCTION()
	void OnCodyDropped()
	{
		IsCarryingCodyLevelSequeunce = nullptr;
	}

	UFUNCTION()
	void SwingPointAttached(AHazePlayerCharacter Player)
	{
		IsCarryingCodyLevelSequeunce.CustomTimeDilation = 1.f;
		OnBeakPointAttached.Broadcast(Player);
	}

	UFUNCTION()
	void SwingPointDetached(AHazePlayerCharacter Player)
	{
		OnBeakPointDetached.Broadcast(Player);
	}
}

// The capability that will timedilate the cutscene from codys abilities
class UClockworkEvilBirdTimeDilationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default TickGroup = ECapabilityTickGroups::GamePlay;

	AClockworkEvilBird BirdOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        BirdOwner = Cast<AClockworkEvilBird>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(BirdOwner.IsCarryingCodyLevelSequeunce == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(BirdOwner.IsCarryingCodyLevelSequeunce == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		BirdOwner.IsCarryingCodyLevelSequeunce.CustomTimeDilation = BirdOwner.CustomTimeDilation;
	}

}