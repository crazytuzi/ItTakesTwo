import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.ChessPieceAbilityComponent;

class UCastleChessBossPieceSummonCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ChessPiece");
	default CapabilityTags.Add(n"ChessPieceSummon");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ACastleEnemy Piece;
	UChessPieceAbilityComponent PieceAbilityComp;



	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Piece = Cast<ACastleEnemy>(Owner);
		PieceAbilityComp = UChessPieceAbilityComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PieceAbilityComp.State != ECastleChessBossPieceState::Summon)
		return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ActiveDuration >= PieceAbilityComp.SummonDuration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Piece.SetActorLocation(PieceAbilityComp.TargetLocation);
		PieceAbilityComp.State = ECastleChessBossPieceState::Idle;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = FMath::Clamp(ActiveDuration / PieceAbilityComp.SummonMovementDuration, 0.f, 1.f);

		float VerticalAlpha = FMath::Sin(Alpha * PI);
		float HorizontalAlpha = Alpha;
		float ScaleAlpha = Alpha;

		if (PieceAbilityComp.VerticalCurve != nullptr)
			VerticalAlpha = PieceAbilityComp.VerticalCurve.GetFloatValue(Alpha);

		FVector TargetLocation = FMath::Lerp(PieceAbilityComp.InitialLocation, PieceAbilityComp.TargetLocation, HorizontalAlpha);
		TargetLocation += FVector::UpVector * PieceAbilityComp.SummonHeight * VerticalAlpha;

		Piece.SetActorLocation(TargetLocation);
	}
}