import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAI.Charger.CastleEnemyChargerComponent;
import Rice.Math.MathStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent;

class UCastleEnemyAITelegraphChargeCapability : UCharacterMovementCapability
{
    default CapabilityDebugCategory = n"Castle";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 55;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"CastleEnemyAI");
    default CapabilityTags.Add(n"CastleEnemyCharge");
    default CapabilityTags.Add(n"CastleEnemyChargeTelegraph");

	ACastleEnemy Charger;
	UCastleEnemyChargerComponent ChargerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Charger = Cast<ACastleEnemy>(Owner);
		ChargerComp = UCastleEnemyChargerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (ChargerComp.ChargeTarget == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (ChargerComp.bHasTelegraphed)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (ActiveDuration >= ChargerSettings::ChargeTelegraphTime)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ChargerComp.bHasTelegraphed = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"ChargerTelegraph");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove,  n"CastleEnemyCharge", n"ChargeTelegraph");
			
			CrumbComp.LeaveMovementCrumb();	
		}
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{		
			FVector ChargeTargetLocation = ChargerComp.ChargeTarget.ActorLocation;
			auto ChargePlayer = Cast<AHazePlayerCharacter>(ChargerComp.ChargeTarget);

			// If the player is in the process of blinking, target the
			// original location, not the current one
			if (ChargePlayer != nullptr)
			{
				auto CastleComp = UCastleComponent::Get(ChargePlayer);
				if (CastleComp != nullptr)
				{
					if (CastleComp.bIsBlinking)
						ChargeTargetLocation = CastleComp.BlinkStartLocation;
				}
			}

			// Get the direction to the target and flatten it
			FVector ToChargeTarget = ChargeTargetLocation - Owner.ActorLocation;
			ToChargeTarget = Math::ConstrainVectorToSlope(ToChargeTarget, FVector::UpVector, FVector::UpVector);
			FVector DirectionToChargeTarget = ToChargeTarget.GetSafeNormal();

			MoveComp.SetTargetFacingDirection(DirectionToChargeTarget, 3.f);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		FrameMove.ApplyTargetRotationDelta(); 		
	}
}