import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAI.Charger.CastleEnemyChargerComponent;
import Rice.Math.MathStatics;
import Rice.TemporalLog.TemporalLogStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleChargableComponent;

class UCastleEnemyAIPostStunTurnCapability : UCharacterMovementCapability
{
    default CapabilityDebugCategory = n"Castle";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 52;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"CastleEnemyAI");
    default CapabilityTags.Add(n"CastleEnemyCharge");
    default CapabilityTags.Add(n"CastleEnemyChargeStun");

	ACastleEnemy Charger;
	UCastleEnemyChargerComponent ChargerComp;

	FVector InitialDirection;

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

		if (ChargerComp.bHasTurnedPostStun)
			return EHazeNetworkActivation::DontActivate;

		if (ChargerComp.ChargeTarget == nullptr)
			return EHazeNetworkActivation::DontActivate;

		FVector ToTarget = ChargerComp.ChargeTarget.ActorLocation - Owner.ActorLocation;
		ToTarget = ToTarget.ConstrainToPlane(MoveComp.WorldUp);
		ToTarget.Normalize();
		const float AngleDifference = ToTarget.AngularDistance(Owner.ActorForwardVector) * RAD_TO_DEG;
		//PrintScaled("AngleDifference: " + AngleDifference);

		if (AngleDifference < ChargerSettings::PostStunTurnMinimumAngle)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (ActiveDuration >= ChargerSettings::PostStunTurnDuration)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ChargerComp.bHasTurnedPostStun = true;
		InitialDirection = Owner.ActorForwardVector;

		FVector ToTarget = ChargerComp.ChargeTarget.ActorLocation - Owner.ActorLocation;
		ToTarget.Normalize();

		ChargerComp.bTurningRight = ToTarget.DotProduct(Owner.ActorRightVector) > 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		ChargerComp.StunDuration += DeltaTime;

		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"ChargeTurn");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, n"CastleEnemyCharge", n"ChargeTurn");
			
			CrumbComp.LeaveMovementCrumb();	
		}
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{	
			FVector ToTarget = ChargerComp.ChargeTarget.ActorLocation - Owner.ActorLocation;
			ToTarget.Normalize();

			// It might be possible to snap the other direction if the player is moving quickly while using a lerp, but feels unlikely.
			const float CurrentDuration = FMath::Max(0.f, ActiveDuration - ChargerSettings::PostStunTurnStationaryDuration);
			const float MaxDuration = ChargerSettings::PostStunTurnRotationFinishedDuration - ChargerSettings::PostStunTurnStationaryDuration;
			float TurnAlpha = FMath::Clamp(CurrentDuration / MaxDuration, 0.f, 1.f);
			TurnAlpha = FMath::Pow(TurnAlpha, 0.8f);		


			FVector NewDirection = Owner.ActorForwardVector;
			if (ActiveDuration >= ChargerSettings::PostStunTurnStationaryDuration)
			{
				//FRotator InitialRotation = FRotator::MakeFromX(
				NewDirection = Math::SlerpVectorTowards(InitialDirection, ToTarget, TurnAlpha).GetSafeNormal();
			}

			MoveComp.SetTargetFacingDirection(NewDirection);
			FrameMove.ApplyTargetRotationDelta();
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