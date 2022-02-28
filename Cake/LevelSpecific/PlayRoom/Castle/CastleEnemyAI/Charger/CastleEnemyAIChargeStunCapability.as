import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAI.Charger.CastleEnemyChargerComponent;
import Rice.Math.MathStatics;
import Rice.TemporalLog.TemporalLogStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleChargableComponent;

class UCastleEnemyAIChargeStunCapability : UCharacterMovementCapability
{
    default CapabilityDebugCategory = n"Castle";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 50;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"CastleEnemyAI");
    default CapabilityTags.Add(n"CastleEnemyCharge");
    default CapabilityTags.Add(n"CastleEnemyChargeStun");

	ACastleEnemyCharger Charger;
	UCastleEnemyChargerComponent ChargerComp;

	FVector StartLocation;
	FVector BounceTargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Charger = Cast<ACastleEnemyCharger>(Owner);
		ChargerComp = UCastleEnemyChargerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!Owner.IsAnyCapabilityActive(n"CastleEnemyChargeCharge"))
		return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.ForwardHit.bBlockingHit)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (ActiveDuration >= ChargerSettings::ChargeStunTime)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{

		// The only chargable comp in the area are the fires, so if chargable is valid, we assume that we hit a fire
		UCastleChargableComponent ChargableComponent = UCastleChargableComponent::Get(MoveComp.ForwardHit.Actor);
		if (ChargableComponent == nullptr)
		{
			// If the actor hit didn't have have a chargable comp, so lets do a trace to find out if nearby actors do
			TArray<EObjectTypeQuery> ObjectTypes;
			ObjectTypes.Add(EObjectTypeQuery::WorldDynamic);
			TArray<AActor> ActorsToIgnore;
			ActorsToIgnore.Add(Owner);
			TArray<AActor> Actors;
			UClass ClassFilter = AHazeActor::StaticClass();
			System::SphereOverlapActors(MoveComp.ForwardHit.ImpactPoint, 250.f, ObjectTypes, ClassFilter, ActorsToIgnore, Actors);
			//System::DrawDebugSphere(MoveComp.ForwardHit.ImpactPoint, 250.f, 20, FLinearColor::Red, 5.f, 3.f);

			for (AActor Actor : Actors)
			{
				// If we find something with a chargable, lets break and use this as the hit
				ChargableComponent = UCastleChargableComponent::Get(Actor);
				if (ChargableComponent != nullptr)
					break;
			}
		}

		ActivationParams.AddObject(n"HitChargable", ChargableComponent);
		ActivationParams.AddVector(n"HitLocation", MoveComp.ForwardHit.Location);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Charger.BlockCapabilities(n"CastleEnemyChargeSeek", this);
		ChargerComp.ResetCharger();
		ChargerComp.StunDuration = 0.f;
		ChargerComp.bHasTurnedPostStun = false;
		ChargerComp.bShouldTriggerRockfall = true;

		StartLocation = Owner.ActorLocation;
		BounceTargetLocation = StartLocation - (Owner.ActorForwardVector * ChargerSettings::ChargeStunBounceDistance);

		Charger.OnChargerHitWall.Broadcast();

		if (ChargerComp.StunCameraShake.IsValid())
		{
			float DistanceToCharger = 0.f;
			GetNearestPlayer(Owner.ActorLocation, DistanceToCharger);

			const float MinDistance = 500.f;
			const float MaxDistance = 2750.f;
			float Scale = 1.f - FMath::Min(FMath::Max(DistanceToCharger - MinDistance, 0.f) / (MaxDistance - MinDistance), 1.f);

			Game::May.PlayCameraShake(ChargerComp.StunCameraShake, Scale * 5.f);
		}

		if (ChargerComp.StunEffect != nullptr)
			Niagara::SpawnSystemAtLocation(ChargerComp.StunEffect, ActivationParams.GetVector(n"HitLocation"));

		UCastleChargableComponent ChargableComponent = Cast<UCastleChargableComponent>(ActivationParams.GetObject(n"HitChargable"));
		if (ChargableComponent != nullptr)
		{
			ChargableComponent.HitChargableActor();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Charger.UnblockCapabilities(n"CastleEnemyChargeSeek", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		ChargerComp.StunDuration += DeltaTime;

		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"ChargerStun");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, n"CastleEnemyCharge", n"ChargeStun");
			
			CrumbComp.LeaveMovementCrumb();	
		}
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{	
			FVector NewLocation = FMath::VInterpTo(Owner.ActorLocation, BounceTargetLocation, DeltaTime, ChargerSettings::ChargeStunInterpSpeed);
			FVector DeltaMove = NewLocation - Owner.ActorLocation;

			FrameMove.ApplyDelta(DeltaMove);
			MoveComp.SetTargetFacingDirection(Owner.ActorForwardVector);
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