class AClassicMeditationGeoActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Walls;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent ShrineCloth;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MoonPillowOne;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MoonPillowTwo;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PillowOne;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PillowTwo;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PillowThree;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PillowFour;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PillowFive;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PillowSix;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PillowSeven;
	UPROPERTY()
	EMeditationTentPlayer MeditationTentPlayer = EMeditationTentPlayer::May;
	bool bTrippynessActive = false; 
	FHazeAcceleratedFloat AcceleratedFloat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MakeGeoVisibleForOnePlayer();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bTrippynessActive)
		{
			if(AcceleratedFloat.Value < 1)
			{
				AcceleratedFloat.SpringTo(1.1, 0.01, 1, DeltaSeconds);
				ShrineCloth.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
				MoonPillowOne.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
				MoonPillowTwo.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
				PillowTwo.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
				PillowThree.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
				PillowFour.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
				PillowFive.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
				PillowSix.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
				PillowSeven.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
			}
		}
		else
		{
			if(AcceleratedFloat.Value > 0)
			{
				AcceleratedFloat.SpringTo(0, 10, 1, DeltaSeconds);
				ShrineCloth.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
				MoonPillowOne.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
				MoonPillowTwo.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
				PillowTwo.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
				PillowThree.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
				PillowFour.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
				PillowFive.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
				PillowSix.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
				PillowSeven.SetScalarParameterValueOnMaterials(n"Trippyness", AcceleratedFloat.Value);
			}
		}
	}

	void MakeGeoVisibleForOnePlayer()
	{
		if(MeditationTentPlayer == EMeditationTentPlayer::May)
		{
			Walls.SetRenderedForPlayer(Game::GetCody(), false);
			ShrineCloth.SetRenderedForPlayer(Game::GetCody(), false);
			MoonPillowOne.SetRenderedForPlayer(Game::GetCody(), false);
			MoonPillowTwo.SetRenderedForPlayer(Game::GetCody(), false);
			PillowOne.SetRenderedForPlayer(Game::GetCody(), false);
			PillowTwo.SetRenderedForPlayer(Game::GetCody(), false);
			PillowThree.SetRenderedForPlayer(Game::GetCody(), false);
			PillowFour.SetRenderedForPlayer(Game::GetCody(), false);
			PillowFive.SetRenderedForPlayer(Game::GetCody(), false);
			PillowSix.SetRenderedForPlayer(Game::GetCody(), false);
			PillowSeven.SetRenderedForPlayer(Game::GetCody(), false);
		}
		else if(MeditationTentPlayer == EMeditationTentPlayer::Cody)
		{
			Walls.SetRenderedForPlayer(Game::GetMay(), false);
			ShrineCloth.SetRenderedForPlayer(Game::GetMay(), false);
			MoonPillowOne.SetRenderedForPlayer(Game::GetMay(), false);
			MoonPillowTwo.SetRenderedForPlayer(Game::GetMay(), false);
			PillowOne.SetRenderedForPlayer(Game::GetMay(), false);
			PillowTwo.SetRenderedForPlayer(Game::GetMay(), false);
			PillowThree.SetRenderedForPlayer(Game::GetMay(), false);
			PillowFour.SetRenderedForPlayer(Game::GetMay(), false);
			PillowFive.SetRenderedForPlayer(Game::GetMay(), false);
			PillowSix.SetRenderedForPlayer(Game::GetMay(), false);
			PillowSeven.SetRenderedForPlayer(Game::GetMay(), false);
		}
	}

	UFUNCTION()
	void StartTextureSwap()
	{
		
		bTrippynessActive = true;
	}
	UFUNCTION()
	void ReverseTextureSwap()
	{
		bTrippynessActive = false;
	}
}

enum EMeditationTentPlayer
{
	May,
	Cody
}


