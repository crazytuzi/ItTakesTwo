import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAI.Charger.CastleEnemyChargerComponent;
import Rice.Math.MathStatics;
import Vino.Movement.Capabilities.KnockDown.KnockdownStatics;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemyCharger;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleEnemyList;

class UCastleEnemyAIChargeCapability : UCharacterMovementCapability
{
    default CapabilityDebugCategory = n"Castle";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 60;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"CastleEnemyAI");
    default CapabilityTags.Add(n"CastleEnemyCharge");
    default CapabilityTags.Add(n"CastleEnemyChargeCharge");

	ACastleEnemyCharger Charger;
	UCastleEnemyChargerComponent ChargerComp;

	FVector DirectionToChargeTarget;
	float CurrentSpeed = 0.f;

	UNiagaraComponent TrailComp;

	TArray<AActor> HitDuringThisCharge;

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

		if (ChargerComp.ChargeTarget == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!ChargerComp.bHasTelegraphed)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (ChargerComp.ChargeTarget == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		// if (ActiveDuration >= ChargerSettings::ChargeDurationMax)
		// 	EHazeNetworkDeactivation::DeactivateFromControl;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DirectionToChargeTarget = Charger.ActorForwardVector;
		Charger.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
		Charger.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::Enemy, ECollisionResponse::ECR_Ignore);

		CurrentSpeed = ChargerSettings::ChargeSpeedInitial;
		HitDuringThisCharge.Empty();
		
		if (ChargerComp.ChargeTrailEffect != nullptr) 
			TrailComp = Niagara::SpawnSystemAttached(ChargerComp.ChargeTrailEffect, Charger.RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Charger.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
		Charger.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::Enemy, ECollisionResponse::ECR_Block);


		for (auto Player : Game::Players)
		{
			if (!Player.HasControl())
				continue;
			if (Player.IsAnyCapabilityActive(n"KnockDown"))
				continue;
			if (!Player.CanPlayerBeDamaged())
				continue;

			FVector ToPlayer = Player.ActorLocation - Charger.ActorLocation;

			// Is the player infront of the charger
			float ForwardDot = ToPlayer.DotProduct(Charger.ActorForwardVector);
			float HorizontalDot = FMath::Abs(ToPlayer.DotProduct(Charger.ActorRightVector));

			if (IsDebugActive())
			{
				System::DrawDebugLine(Charger.ActorLocation, Charger.ActorLocation + Charger.ActorForwardVector * 800.f, FLinearColor::Red, 5.f, 4.f);
				System::DrawDebugLine(Charger.ActorLocation, Charger.ActorLocation + Charger.ActorRightVector * 325.f, FLinearColor::Red, 5.f, 4.f);
				System::DrawDebugLine(Charger.ActorLocation, Charger.ActorLocation - Charger.ActorRightVector * 325.f, FLinearColor::Red, 5.f, 4.f);
			}

			if (ForwardDot <= 0.f || ForwardDot > 800.f)
				continue;

			if (HorizontalDot > 325.f)
				continue;

			FVector KnockDirection = -Charger.ActorForwardVector;
			KnockDirection += Charger.ActorRightVector * FMath::Sign(KnockDirection.DotProduct(ToPlayer));
			KnockDirection.Normalize();

			float KnockForce = 750.f;
			FVector KnockImpulse = KnockDirection * KnockForce + FVector(0.f, 0.f, 1200.f);
			Player.KnockdownActor(KnockImpulse);
			Player.DamagePlayerHealth(Charger.ChargePlayerDamage, Charger.ChargePlayerDamageEffect);

			if (Charger.ChargePlayerDamageForceFeedback != nullptr)
				Player.PlayForceFeedback(Charger.ChargePlayerDamageForceFeedback, false, false, n"Damage");

			HitDuringThisCharge.Add(Player);
		}


		if (ChargerComp.ChargeTrailEffect != nullptr)
		{
			TrailComp.DestroyComponent(Owner);
			TrailComp == nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"ChargerCharge");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove,  n"CastleEnemyCharge");
			
			CrumbComp.LeaveMovementCrumb();	
		}

		// Knock back players if we hit them
		for (auto Player : Game::Players)
		{
			if (!Player.HasControl())
				continue;
			if (Player.IsAnyCapabilityActive(n"KnockDown"))
				continue;
			if (!Player.CanPlayerBeDamaged())
				continue;

			FVector KnockDirection;
			if (!CalculateChargeKnock(Player, KnockDirection))
				continue;

			float KnockForce = 750.f;
			FVector KnockImpulse = KnockDirection * KnockForce + FVector(0.f, 0.f, 1200.f);
			Player.KnockdownActor(KnockImpulse);
			Player.DamagePlayerHealth(Charger.ChargePlayerDamage, Charger.ChargePlayerDamageEffect);

			if (Charger.ChargePlayerDamageForceFeedback != nullptr)
				Player.PlayForceFeedback(Charger.ChargePlayerDamageForceFeedback, false, false, n"Damage");

			HitDuringThisCharge.Add(Player);
		}

		// Knock back enemies if we hit them
		auto& AllEnemies = GetAllCastleEnemies();
		for (int i = AllEnemies.Num() - 1; i >= 0; --i)
		{
			ACastleEnemy CastleEnemy = AllEnemies[i];
			if (CastleEnemy == nullptr)
				continue;

			FVector KnockDirection;
			if (!CalculateChargeKnock(CastleEnemy, KnockDirection))
				continue;

			FCastleEnemyKnockbackEvent KnockEvent;
			KnockEvent.Source = Game::GetFirstLocalPlayer();
			KnockEvent.Location = CastleEnemy.ActorLocation;
			KnockEvent.Direction = KnockDirection;
			KnockEvent.VerticalForce = 2.f;
			KnockEvent.HorizontalForce = 2.f;
			CastleEnemy.KnockBack(KnockEvent);

			FCastleEnemyDamageEvent DamageEvent;
			DamageEvent.DamageSource = Charger;
			DamageEvent.DamageDealt = Charger.ChargeEnemyDamage;
			DamageEvent.DamageLocation = CastleEnemy.ActorLocation;
			DamageEvent.DamageDirection = KnockDirection;
			DamageEvent.bIsCritical = true;
			CastleEnemy.TakeDamage(DamageEvent);

			HitDuringThisCharge.Add(CastleEnemy);
		}
	}

	bool CalculateChargeKnock(AHazeCharacter Unit, FVector& OutKnockDirection)
	{
		float Distance = Charger.CapsuleComponent.WorldLocation.DistSquared(Unit.ActorLocation);
		if (Distance > FMath::Square(Unit.CapsuleComponent.CapsuleRadius + Charger.CapsuleComponent.CapsuleRadius))
			return false;

		if (HitDuringThisCharge.Contains(Unit))
			return false;

		FVector DirToUnit = (Unit.ActorLocation - Charger.ActorLocation).GetSafeNormal();
		float DotToUnit = DirToUnit.DotProduct(Charger.ActorForwardVector);
		if (DotToUnit < 0.1f)
			return false;

		if (DotToUnit > 0.99f)
			OutKnockDirection = Charger.ActorForwardVector.CrossProduct(FVector::UpVector);
		else
			OutKnockDirection = Charger.ActorForwardVector.CrossProduct(-DirToUnit);
		return true;
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{	
			CurrentSpeed = FMath::Clamp(CurrentSpeed + (ChargerSettings::ChargeAcceleration * DeltaTime), 0.f, ChargerSettings::ChargeSpeed);
			FVector Velocity = DirectionToChargeTarget * CurrentSpeed;
			MoveComp.SetTargetFacingDirection(DirectionToChargeTarget);

			FrameMove.ApplyVelocity(Velocity);
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