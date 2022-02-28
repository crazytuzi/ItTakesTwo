import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.CastleChessBossPieceTelegraphCapability;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.Chessboard;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.Rook.CastleChessBossRookComponent;

class UCastleChessBossRookTelegraphCapability : UCastleChessBossPieceTelegraphCapability
{
	UCastleChessBossRookComponent RookComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams) override
	{
		Super::Setup(SetupParams);

		RookComp = UCastleChessBossRookComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams) override
	{
		Super::OnActivated(ActivationParams);

		FVector2D Epicenter = PieceComp.Chessboard.GetClosestGridPosition(Owner.ActorLocation);

		for (FTileSquareTimer SquareTimer : RookComp.TilesToLower)
		{
			if (Epicenter == SquareTimer.TileCoordinate)
				continue;
			
			AChessTile Tile = PieceAbilityComp.Chessboard.GetTileActor(SquareTimer.TileCoordinate);

			Tile.StartTremble();
		}
	}
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);

		if (PieceAbilityComp.State == ECastleChessBossPieceState::Death || PieceAbilityComp.Chessboard.bChessboardDisabled)
		{
			FVector2D Epicenter = PieceComp.Chessboard.GetClosestGridPosition(Owner.ActorLocation);

			for (FTileSquareTimer SquareTimer : RookComp.TilesToLower)
			{
				if (Epicenter == SquareTimer.TileCoordinate)
					continue;
				
				AChessTile Tile = PieceAbilityComp.Chessboard.GetTileActor(SquareTimer.TileCoordinate);

				Tile.StopTremble();
			}
		}
	}

	void SpawnTelegraphDecal()
	{
		if (PieceAbilityComp.TelegraphDecalType.IsValid())
		{
			FVector CenterLocation = PieceComp.Chessboard.GetSquareCenter(PieceAbilityComp.Coordinate);
			const float Distance = 350.f;
			//const float Distance = 200.f;

			FRotator Rot1(0.f, 0.f, 0.f);
			FVector Dir1 = Rot1.ForwardVector * Distance;
			//FVector Dir1 = Rot1.RightVector * Distance;
			PieceAbilityComp.TelegraphDecals.Add(Cast<ADecalActor>(SpawnActor(PieceAbilityComp.TelegraphDecalType, CenterLocation + Dir1, Rot1)));
			//DecalMaterialInstances.Add(PieceAbilityComp.TelegraphDecals[0].Decal.CreateDynamicMaterialInstance());

			FRotator Rot2(0.f, 90.f, 0.f);
			FVector Dir2 = Rot2.ForwardVector * Distance;
			//FVector Dir2 = Rot2.RightVector * Distance;
			PieceAbilityComp.TelegraphDecals.Add(Cast<ADecalActor>(SpawnActor(PieceAbilityComp.TelegraphDecalType, CenterLocation + Dir2, Rot2)));
			//DecalMaterialInstances.Add(PieceAbilityComp.TelegraphDecals[1].Decal.CreateDynamicMaterialInstance());

			FRotator Rot3(0.f, 180.f, 0.f);
			FVector Dir3 = Rot3.ForwardVector * Distance;
			//FVector Dir3 = Rot3.RightVector * Distance;
			PieceAbilityComp.TelegraphDecals.Add(Cast<ADecalActor>(SpawnActor(PieceAbilityComp.TelegraphDecalType, CenterLocation + Dir3, Rot3)));
			//DecalMaterialInstances.Add(PieceAbilityComp.TelegraphDecals[2].Decal.CreateDynamicMaterialInstance());

			FRotator Rot4(0.f, 270.f, 0.f);
			FVector Dir4 = Rot4.ForwardVector * Distance;
			//FVector Dir4 = Rot4.RightVector * Distance;
			PieceAbilityComp.TelegraphDecals.Add(Cast<ADecalActor>(SpawnActor(PieceAbilityComp.TelegraphDecalType, CenterLocation + Dir4, Rot4)));
			//DecalMaterialInstances.Add(PieceAbilityComp.TelegraphDecals[3].Decal.CreateDynamicMaterialInstance());		
		}
	}
}