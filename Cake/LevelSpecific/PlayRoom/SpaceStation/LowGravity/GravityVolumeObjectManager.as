import Cake.LevelSpecific.PlayRoom.SpaceStation.LowGravity.GravityVolumeObject;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.MovementSettings;
import Vino.Movement.Jump.CharacterJumpSettings;
import Vino.Movement.Dash.CharacterDashSettings;
import Vino.MinigameScore.MinigameComp;

event void FGravityVolumeRaceEvent();

UCLASS(Abstract)
class AGravityVolumeObjectManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent)
	UMinigameComp MinigameComp;
	default MinigameComp.MinigameTag = EMinigameTag::LowGravityRoom;
	
	UPROPERTY()
	FGravityVolumeRaceEvent OnRaceStarted;

	UPROPERTY()
	FGravityVolumeRaceEvent OnRaceFinished;

	UPROPERTY()
	FGravityVolumeRaceEvent OnRaceCancelled;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface GhostMaterial;

	UPROPERTY(EditDefaultsOnly)
	FText CountdownText;

	UPROPERTY(EditDefaultsOnly)
	UMovementSettings LowGravityMovementSettings;

	UPROPERTY(EditDefaultsOnly)
	UCharacterJumpSettings LowGravityJumpSettings;

	UPROPERTY(EditDefaultsOnly)
	UCharacterAirDashSettings LowGravityAirDashSettings;

	TArray<AGravityVolumeObject> AllObjects;

	UPROPERTY(NotEditable)
	bool bRaceActive = false;

	UPROPERTY()
	bool bShowEndPoints;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bShowEndPoints)
		{
			TArray<AGravityVolumeObject> Objects;
			GetAllActorsOfClass(Objects);
			for (AGravityVolumeObject Object : Objects)
			{
				Object.RemoveDebugMesh();
				Object.DebugMesh = UStaticMeshComponent::Create(Object);
				Object.DebugMesh.SetRelativeLocation(FVector(Object.HoverHorizontalOffset, 0.f, Object.DebugMesh.RelativeLocation.Z));
				Object.DebugMesh.SetMaterial(0, GhostMaterial);
				Object.DebugMesh.SetStaticMesh(Object.ObjectMesh.StaticMesh);
				Object.DebugMesh.SetRelativeScale3D(Object.ObjectMesh.RelativeScale3D);
			}
		}
		else
		{
			TArray<AGravityVolumeObject> Objects;
			GetAllActorsOfClass(Objects);
			for (AGravityVolumeObject Object : Objects)
			{
				Object.RemoveDebugMesh();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(AllObjects);
		for (AGravityVolumeObject Object : AllObjects)
		{
			Object.OnClaimedByPlayer.AddUFunction(this, n"ObjectClaimed");
		}

		SetActorTickEnabled(false);

		MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"StartCountDown");
		MinigameComp.OnTutorialCancel.AddUFunction(this, n"TutorialCancelled");
	}

	UFUNCTION(NotBlueprintCallable)
	void ObjectClaimed(AGravityVolumeObject Object, AHazePlayerCharacter Player, bool bPlayerChanged)
	{
		if (!bRaceActive)
			return;

		int CodyScoreAdjustment = 0;
		int MayScoreAdjustment = 0;

		if (Player == Game::GetCody())
		{
			CodyScoreAdjustment++;
			if (bPlayerChanged)
				MayScoreAdjustment--;
		}
		else if (Player == Game::GetMay())
		{
			MayScoreAdjustment++;
			if (bPlayerChanged)
				CodyScoreAdjustment--;
		}

		if (bPlayerChanged)
			MinigameComp.PlayTauntAllVOBark(Player);
		else
			MinigameComp.PlayTauntGenericVOBark(Player);

		if (CodyScoreAdjustment != 0)
		{
			MinigameComp.AdjustScore(Game::GetCody(), CodyScoreAdjustment);
			ShowWorldScoreWidget(Game::GetCody(), CodyScoreAdjustment);
		}
		if (MayScoreAdjustment != 0)
		{
			MinigameComp.AdjustScore(Game::GetMay(), MayScoreAdjustment);
			ShowWorldScoreWidget(Game::GetMay(), MayScoreAdjustment);
		}
	}

	void ShowWorldScoreWidget(AHazePlayerCharacter Player, int ScoreAdjustment)
	{
		FMinigameWorldWidgetSettings MinigameWorldSettings;
		MinigameWorldSettings.MinigameTextMovementType = EMinigameTextMovementType::AccelerateToHeight;
		MinigameWorldSettings.TextJuice = EInGameTextJuice::BigChange;
		MinigameWorldSettings.MoveSpeed = 30.f;
		MinigameWorldSettings.TimeDuration = 0.5f;
		MinigameWorldSettings.FadeDuration = 0.6f;
		MinigameWorldSettings.TargetHeight = 140.f;
		MinigameWorldSettings.MinigameTextColor = EMinigameTextColor::May;
		if (Player.IsCody())
			MinigameWorldSettings.MinigameTextColor = EMinigameTextColor::Cody;
		
		EMinigameTextPlayerTarget ScorePlayer = EMinigameTextPlayerTarget::May;
		if (Player.IsCody())
			ScorePlayer = EMinigameTextPlayerTarget::Cody;

		FString ScoreString;
		if (ScoreAdjustment > 0)
			ScoreString = n"+ " + String::Conv_IntToString(ScoreAdjustment);
		else
			ScoreString = String::Conv_IntToString(ScoreAdjustment);

		FVector ScoreLocation = Player.ActorLocation + (Player.ViewRotation.RightVector * 50.f) + (Player.MovementWorldUp * 125.f);
		if (ScoreAdjustment < 0)
			ScoreLocation -= (Player.ViewRotation.RightVector * 100.f);
		MinigameComp.CreateMinigameWorldWidgetText(ScorePlayer, ScoreString, ScoreLocation, MinigameWorldSettings);
	}

	UFUNCTION()
	void StartRace()
	{
		MinigameComp.ResetScoreBoth();

		MinigameComp.ActivateTutorial();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (Player.HasControl())
				Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		}

		ApplyCameraModifiersToPlayers();
	}

	UFUNCTION(NotBlueprintCallable)
	void StartCountDown()
	{
		MinigameComp.StartCountDown();
		MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"CountdownFinished");
		MinigameComp.OnTimerCompletedEvent.AddUFunction(this, n"TimerFinished");
		OnRaceStarted.Broadcast();

		for (AGravityVolumeObject Object : AllObjects)
		{
			Object.LowGravityActivated();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void TutorialCancelled()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (Player.HasControl())
				Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		}

		ClearCameraModifersFromPlayers();

		OnRaceCancelled.Broadcast();
	}

	UFUNCTION(NotBlueprintCallable)
	void CountdownFinished()
	{
		bRaceActive = true;	
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (Player.HasControl())
				Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		}

		ApplyGravityModifersToPlayers();
	}

	UFUNCTION(NotBlueprintCallable)
	void TimerFinished()
	{
		FinishRace();
	}

	UFUNCTION()
	void FinishRace(AHazePlayerCharacter OverrideWinner = nullptr)
	{
		if (!bRaceActive)
			return;

		SetActorTickEnabled(false);

		bRaceActive = false;
		if (HasControl())
		{
			EMinigameWinner Winner = EMinigameWinner::Draw;
			if (OverrideWinner == nullptr)
			{
				if (MinigameComp.ScoreData.CodyScore > MinigameComp.ScoreData.MayScore)
					Winner = EMinigameWinner::Cody;
				else if (MinigameComp.ScoreData.MayScore > MinigameComp.ScoreData.CodyScore)
					Winner = EMinigameWinner::May;
			}
			else
			{
				if (OverrideWinner == Game::GetCody())
					Winner = EMinigameWinner::Cody;
				else if (OverrideWinner == Game::GetMay())
					Winner = EMinigameWinner::May;
			}
			
			NetDetermineWinner(Winner);
		}
	}

	UFUNCTION(NetFunction)
	void NetDetermineWinner(EMinigameWinner Winner)
	{
		MinigameComp.AnnounceWinner(Winner);

		System::SetTimer(this, n"HideHud", 3.f, false);
		OnRaceFinished.Broadcast();
		ResetGravityObjectOwners();

		ClearGravityModifiersFromPlayers();
		ClearCameraModifersFromPlayers();
	}

	UFUNCTION()
	void HideHud()
	{
		// MinigameComp.EndGameHud();
	}

	UFUNCTION()
	void CancelRace()
	{
		FinishRace();
	}

	void ApplyGravityModifersToPlayers()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.ApplySettings(LowGravityMovementSettings, this);
			Player.ApplySettings(LowGravityJumpSettings, this);
			Player.ApplySettings(LowGravityAirDashSettings, this);

			Player.BlockCapabilities(MovementSystemTags::SkyDive, this);
		}
	}

	void ClearGravityModifiersFromPlayers()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.ClearSettingsByInstigator(this);
			Player.UnblockCapabilities(MovementSystemTags::SkyDive, this);
			UMovementSettings::ClearGravityMultiplier(Player, this);
		}
	}

	UFUNCTION()
	void ApplyCameraModifiersToPlayers()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.ApplyPivotLagSpeed(FVector(0.5f, 0.5f, 0.38f), this);
			Player.ApplyIdealDistance(1500.f, FHazeCameraBlendSettings(3.f), this);
		}
	}

	void ClearCameraModifersFromPlayers()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.ClearPivotLagSpeedByInstigator(this);
			Player.ClearIdealDistanceByInstigator(this, 3.f);
		}
	}

	UFUNCTION()
	void ResetGravityObjectOwners()
	{
		for (AGravityVolumeObject Object : AllObjects)
		{
			Object.ResetOwningPlayer();
			Object.bCanBeClaimed = false;
		}
	}

	UFUNCTION()
	void StopHovering()
	{
		for (AGravityVolumeObject Object : AllObjects)
		{
			Object.LowGravityDeactivated();
			Object.StopHovering();
		}
	}

	UFUNCTION(CallInEditor)
	void ResetMeshRootOffset()
	{
		TArray<AGravityVolumeObject> Objects;
		GetAllActorsOfClass(Objects);
		for (AGravityVolumeObject Object : Objects)
		{
			Object.MeshRoot.SetRelativeLocation(FVector(0.f, 0.f, 339.f));
		}
	}
}