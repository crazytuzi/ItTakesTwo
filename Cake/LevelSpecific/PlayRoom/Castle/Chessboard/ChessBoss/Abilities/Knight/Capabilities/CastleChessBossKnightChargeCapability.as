import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.ChessPieceAbilityComponent;
import Vino.Movement.Capabilities.KnockDown.KnockdownStatics;

class UCastleChessBossKnightChargeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ChessPiece");
	default CapabilityTags.Add(n"ChessPieceAction");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 105;

	ACastleEnemy Piece;
	UChessPieceComponent PieceComp;
	UChessPieceAbilityComponent PieceAbilityComp;

	const float InitialSpeed = 400.f;
	const float Acceleration = 300.f;
	const float MaximumSpeed = 1750.f;

	float CurrentSpeed = 100.f;

	FVector TargetLocation;
	FVector MoveDirection;

	bool bMoveComplete = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Piece = Cast<ACastleEnemy>(Owner);
		PieceComp = UChessPieceComponent::GetOrCreate(Owner);
		PieceAbilityComp = UChessPieceAbilityComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PieceAbilityComp.State != ECastleChessBossPieceState::TelegraphComplete)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bMoveComplete)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PieceAbilityComp.State = ECastleChessBossPieceState::Action;

		FVector2D TargetGridPosition = PieceComp.Chessboard.GetClosestGridPosition(Owner.ActorLocation + (Owner.ActorForwardVector * 5000.f));
		TargetLocation = PieceComp.Chessboard.GetSquareCenter(TargetGridPosition);
		MoveDirection = (TargetLocation - Owner.ActorLocation).GetSafeNormal();

		CurrentSpeed = InitialSpeed;

		Piece.CapsuleComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		if (PieceAbilityComp.ActionStartEffect != nullptr)
			Niagara::SpawnSystemAttached(PieceAbilityComp.ActionStartEffect, Piece.RootComponent, NAME_None, FVector::ZeroVector, Owner.ActorRotation, EAttachLocation::SnapToTarget, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{		
		if (PieceAbilityComp.ActionEndEffect != nullptr)
			Niagara::SpawnSystemAtLocation(PieceAbilityComp.ActionEndEffect, Owner.ActorLocation, Owner.ActorRotation);

		PieceAbilityComp.State = ECastleChessBossPieceState::ActionComplete;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if (Piece.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData Request;
			Request.AnimationTag = n"CastleEnemyPiece";

			Piece.Mesh.RequestLocomotion(Request);
		}

		CurrentSpeed = FMath::Min(CurrentSpeed + Acceleration * DeltaTime, MaximumSpeed);
		FVector DeltaMove = MoveDirection * CurrentSpeed * DeltaTime;

		FVector ToTarget = TargetLocation - Owner.ActorLocation;
		if (ToTarget.Size() <= DeltaMove.Size())
		{
			DeltaMove = ToTarget;
			bMoveComplete = true;
		}

		Owner.AddActorWorldOffset(DeltaMove);
		Owner.SetAnimFloatParam(n"Speed", CurrentSpeed);

		// Damage nearby players
		FVector BoxExtents = FVector(Piece.CapsuleComponent.CapsuleRadius, PieceComp.Chessboard.SquareSize.X / 2.f, Piece.CapsuleComponent.CapsuleHalfHeight);
		TArray<AHazePlayerCharacter> Players = GetAttackablePlayersInBox(Piece.CapsuleComponent.WorldTransform, BoxExtents);

		for (AHazePlayerCharacter Player : Players)
		{
			FCastlePlayerDamageEvent Damage;
			Damage.DamageSource = Owner;
			Damage.DamageDealt = PieceAbilityComp.Damage;
			Damage.DamageEffect = PieceAbilityComp.DamageEffect;
			Damage.DamageDirection = Piece.ActorRotation.ForwardVector;
			Damage.DamageLocation = Player.CapsuleComponent.WorldLocation;

			DamageCastlePlayer(Player, Damage);

			// Knock back players if we hit them				
			if (!Player.HasControl())
				continue;
			if (Player.IsAnyCapabilityActive(n"KnockDown"))
				continue;

			FVector ToPlayer = (Player.ActorLocation - Piece.ActorLocation).ConstrainToPlane(FVector(0.f, 0.f, 1.f)).GetSafeNormal();
			FVector KnockDirection = (ToPlayer + (Owner.ActorForwardVector * 2.f)) * 0.5f;
			float KnockForce = 800.f;
			FVector KnockImpulse = KnockDirection * KnockForce;
			Player.KnockdownActor(KnockImpulse);
		}
	}
}