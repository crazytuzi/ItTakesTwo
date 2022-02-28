import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossTags;

UCLASS(Abstract)
class UClockworkBullBossMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(ClockworkBullBossTags::ClockworkBullBoss);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AClockworkBullBoss BullOwner;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BullOwner = Cast<AClockworkBullBoss>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{	
		FString Str = "\n";
		return Str;
	} 

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		if(!BullOwner.CanInitializeMovement(MoveComp))
		{
			return false;
		}
			
		return true;
	}

	void ApplyControlMovement(float DeltaTime, FHazeFrameMovement& MovementData, FVector TargetWorldLocation, FName MovementType = n"Movement")
	{
		FVector FinalTargetLocation = TargetWorldLocation;
		FinalTargetLocation.Z = Owner.GetActorLocation().Z;

		const FVector DeltaMove = FinalTargetLocation - Owner.GetActorLocation();

		float MoveSpeed = MoveComp.GetMoveSpeed();

		// The bullboss can override the movespeed to the chargepoint
		if(BullOwner.ChargeState == EBullBossChargeStateType::MovingToChargePosition && BullOwner.MoveToChargeSpeed >= 0)
		{
			MoveSpeed = BullOwner.MoveToChargeSpeed;
		}

		const float MoveAmount = FMath::Min(DeltaMove.Size(), MoveSpeed * DeltaTime);
		MovementData.ApplyDelta(DeltaMove.GetSafeNormal() * MoveAmount);

		BullOwner.InitializeMovement(MoveComp, MovementData, TargetWorldLocation, MovementType, NAME_None, true);
	}

	void ApplyRemoteMovement(float DeltaTime, FHazeFrameMovement& MovementData, FVector TargetWorldLocation, FName MovementType = n"Movement")
	{
		FHazeActorReplicationFinalized ConsumedParams;
		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

		FHazeReplicatedFrameMovementSettings ApplySettings;
		MovementData.ApplyConsumedCrumbData(ConsumedParams, ApplySettings);
		BullOwner.InitializeMovement(MoveComp, MovementData, TargetWorldLocation, MovementType, NAME_None, false);
	}
};
