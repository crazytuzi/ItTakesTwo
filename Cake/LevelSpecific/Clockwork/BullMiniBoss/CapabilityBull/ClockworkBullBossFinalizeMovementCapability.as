import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossTags;

class UClockworkBullBossFinalizeMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBoss);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(MovementSystemTags::BasicFloorMovement);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 200;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AClockworkBullBoss BullOwner;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	FTransform LastMeshTransform;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BullOwner = Cast<AClockworkBullBoss>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		// Clear the last frames movement since that can be wrong
		BullOwner.ResetPendingMoveData();
		LastMeshTransform = BullOwner.Mesh.GetWorldTransform();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(!HasControl())
		{
			CrumbComp.SetCrumbDebugActive(this, false);
		}
		BullOwner.Mesh.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FinalMovement;
		if(BullOwner.ConsumePendingMovement(DeltaTime, FinalMovement))
		{
			MoveComp.Move(FinalMovement);
			CrumbComp.LeaveMovementCrumb();
		}

		if(!HasControl())
		{
			FVector WantedLocation = FMath::VInterpTo(LastMeshTransform.Location, BullOwner.GetActorLocation(), DeltaTime, 10.f);
			FRotator WantedRotation = FMath::RInterpTo(LastMeshTransform.Rotator(), BullOwner.GetActorRotation(), DeltaTime, 5.f);
			BullOwner.Mesh.SetWorldLocationAndRotation(WantedLocation, WantedRotation);
			LastMeshTransform = BullOwner.Mesh.GetWorldTransform();

			// Print Debug
			CrumbComp.SetCrumbDebugActive(this, IsDebugActive());
		}
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{	
		FString Str = "";

		return Str;
	} 
};
