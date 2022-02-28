import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.ChessPieceAbilityComponent;
class UCastleChessBossPieceDeathCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ChessPiece");
	default CapabilityTags.Add(n"ChessPieceDeath");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 110;

	ACastleEnemy Piece;
	UChessPieceComponent PieceComp;
	UChessPieceAbilityComponent PieceAbilityComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Piece = Cast<ACastleEnemy>(Owner);
		PieceComp = UChessPieceComponent::GetOrCreate(Owner);
		PieceAbilityComp = UChessPieceAbilityComponent::GetOrCreate(Owner);

		Piece.OnKilled.AddUFunction(this, n"OnKilled");
	}

	UFUNCTION()
    void OnKilled(ACastleEnemy DamagedEnemy, bool bKilledByDamage)
    {
		PieceAbilityComp.State = ECastleChessBossPieceState::ActionComplete;
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PieceAbilityComp.State != ECastleChessBossPieceState::ActionComplete)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ActiveDuration >= PieceAbilityComp.DeathDuration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;


		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PieceAbilityComp.State = ECastleChessBossPieceState::Death;

		PieceComp.Chessboard.RemoveActorFromSquare(PieceAbilityComp.Coordinate, Owner);

		if (PieceAbilityComp.DeathEffect != nullptr)
			Niagara::SpawnSystemAtLocation(PieceAbilityComp.DeathEffect, Owner.ActorLocation, Owner.ActorRotation);		

		Piece.SetCapabilityActionState(n"AudioPieceDespawn", EHazeActionState::ActiveForOneFrame);
		Piece.BlockCapabilities(n"ChessPiece", this);
		Piece.SetActorEnableCollision(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Piece.UnblockCapabilities(n"ChessPiece", this);
		Piece.FinalizeDeath();
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

		float Alpha = FMath::Clamp(ActiveDuration / PieceAbilityComp.DeathDuration, 0.f, 1.f);
		Owner.SetActorScale3D(1 - Alpha);		
	}
}