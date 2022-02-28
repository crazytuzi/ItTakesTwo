import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.ChessPieceAbilityComponent;
import Peanuts.Foghorn.FoghornStatics;

class UCastleChessBossPieceTelegraphCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ChessPiece");
	default CapabilityTags.Add(n"ChessPieceTelegraph");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ACastleEnemy Piece;
	UChessPieceComponent PieceComp;
	UChessPieceAbilityComponent PieceAbilityComp;

	UNiagaraComponent TelegraphEffectStart;

	FRotator TelegraphEffectLocation = FRotator::ZeroRotator;

	//TArray<UMaterialInstanceDynamic> DecalMaterialInstances;

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
		if (PieceAbilityComp.Chessboard.bChessboardDisabled)
        	return EHazeNetworkActivation::DontActivate;

		if (PieceAbilityComp.State != ECastleChessBossPieceState::Idle)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PieceAbilityComp.Chessboard.bChessboardDisabled)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (ActiveDuration >= PieceAbilityComp.TelegraphDuration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Shouldn't run if the chessboard is disabled
		if (PieceAbilityComp.Chessboard.bChessboardDisabled)
			return;

		PieceAbilityComp.State = ECastleChessBossPieceState::Telegraph;
		PieceAbilityComp.TelegraphAlpha = 0.f;

		if (PieceAbilityComp.TelegraphStartEffect != nullptr)
			TelegraphEffectStart = Niagara::SpawnSystemAtLocation(PieceAbilityComp.TelegraphStartEffect, Owner.ActorLocation, TelegraphEffectLocation);

		SpawnTelegraphDecal();
		Piece.SetCapabilityActionState(n"AudioPiecePerformAttack", EHazeActionState::ActiveForOneFrame);		

		int Index = FMath::RandRange(0, 1);		
		PieceAbilityComp.Chessboard.PlayTelegraphBark(PieceAbilityComp.TelegraphBarkName[Index]);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		for (ADecalActor Decal : PieceAbilityComp.TelegraphDecals)
		{
			if (Decal != nullptr)
				Decal.DestroyActor();
		}

		if (PieceAbilityComp.State == ECastleChessBossPieceState::Death || PieceAbilityComp.Chessboard.bChessboardDisabled)
		{
			if (TelegraphEffectStart != nullptr)
				TelegraphEffectStart.Deactivate();
		}
		else
		{
			if (PieceAbilityComp.TelegraphEndEffect != nullptr)
				Niagara::SpawnSystemAtLocation(PieceAbilityComp.TelegraphEndEffect, Owner.ActorLocation, Owner.ActorRotation);
			
			PieceAbilityComp.State = ECastleChessBossPieceState::TelegraphComplete;
		}
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

		PieceAbilityComp.TelegraphAlpha = FMath::Clamp(ActiveDuration / PieceAbilityComp.TelegraphDuration, 0.f, 1.f);

		// for (UMaterialInstanceDynamic MatInstance : DecalMaterialInstances)
		// {
		// 	if (MatInstance == nullptr)
		// 		continue;

		// 	float AdjustedAlpha = FMath::Pow(PieceAbilityComp.TelegraphAlpha, 0.75f);
		// 	MatInstance.SetScalarParameterValue(n"FillBlend", AdjustedAlpha);
		// }
	}

	void SpawnTelegraphDecal()
	{
		if (PieceAbilityComp.TelegraphDecalType.IsValid())
		{
			PieceAbilityComp.TelegraphDecals.Add(Cast<ADecalActor>(SpawnActor(PieceAbilityComp.TelegraphDecalType, Owner.ActorLocation)));
			//DecalMaterialInstances.Add(PieceAbilityComp.TelegraphDecals[0].Decal.CreateDynamicMaterialInstance());
		}
	}
}