import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessAudio.CastleChessBossAudioManager;

class UChessboardTileEffectsAudioCapability : UHazeCapability
{	
	AChessboard Chessboard;
	UHazeAkComponent ChessboardHazeAkComp;	
	TArray<AChessTile> CurrentFallingTiles;

	UPROPERTY()
	UAkAudioEvent TilesStartDropping;

	UPROPERTY()
	UAkAudioEvent TilesFinishedDropping;

	UPROPERTY()
	UAkAudioEvent TilesStartReturning;

	UPROPERTY()
	UAkAudioEvent TilesFinishedReturning;

	float Duration = 5.f;
	bool bFinishedReturn = false;
	int32 TileCount = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)	
	{	
		Chessboard = Cast<AChessboard>(Owner);	
		ChessboardHazeAkComp = UHazeAkComponent::GetOrCreate(Owner, n"ChessboardHazeAkComp");
		Chessboard.OnFallingTiles.AddUFunction(this, n"OnTileStatusChange");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Chessboard.bTilesStartedDropping)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ActiveDuration < Duration)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(CurrentFallingTiles.Num() > 0)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(!bFinishedReturn)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ChessboardHazeAkComp.HazePostEvent(TilesStartDropping);	
		bFinishedReturn = false;
		TileCount = 0.f;
		CurrentFallingTiles.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Chessboard.bTilesStartedDropping = false;		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(CurrentFallingTiles.Num () != 0)
		{
			const float PanningValue = GetTilePanningValue();
			HazeAudio::SetPlayerPanning(ChessboardHazeAkComp, nullptr, PanningValue);	
		}
	}

	UFUNCTION()
	void OnTileStatusChange(AChessTile Tile, EChessTileFallingStatus FallingStatus)
	{
		switch(FallingStatus)
		{
			case(EChessTileFallingStatus::StartedFalling):
				CurrentFallingTiles.AddUnique(Tile);
				TileCount ++;
				break;
			case(EChessTileFallingStatus::FinishedFalling):
				CurrentFallingTiles.RemoveSwap(Tile);
				if(CurrentFallingTiles.Num() == 0 && TileCount > 1)
				{
					ChessboardHazeAkComp.HazePostEvent(TilesFinishedDropping);
					TileCount = 0.f;
				}
				break;
			case(EChessTileFallingStatus::StartedReturning):
				if(CurrentFallingTiles.Num() == 0)
				{						
					ChessboardHazeAkComp.HazePostEvent(TilesStartReturning);
				}
				CurrentFallingTiles.AddUnique(Tile);
				TileCount++;
				break;
			case(EChessTileFallingStatus::FinishedReturning):
				CurrentFallingTiles.RemoveSwap(Tile);
				if(CurrentFallingTiles.Num() == 0 && TileCount > 1)
				{	
					ChessboardHazeAkComp.HazePostEvent(TilesFinishedReturning);
					bFinishedReturn = true;
				}
				break;
		}
	}

	float GetTilePanningValue()
	{
		float Sum = 0.f;		
		for(AChessTile& Tile : CurrentFallingTiles)
		{	
			FVector2D OutPos;

			SceneView::ProjectWorldToScreenPosition(SceneView::GetFullScreenPlayer(), Tile.GetActorLocation(), OutPos);

			const float XPos = OutPos.X;
			Sum += XPos;		
		}

		int32 IndexCount = CurrentFallingTiles.Num();
		if(IndexCount > 0)
			Sum =  Sum / IndexCount;

		return HazeAudio::NormalizeRTPC(Sum, 0.f, 1.f, -1.f, 1.f);
	}

}