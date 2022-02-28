import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.LevelActors.MoleTunnel.ChasingMole;
import Vino.Movement.Capabilities.Sprint.CharacterSprintSettings;
import Vino.Time.ActorTimeDilationStatics;
import Vino.Movement.MovementSettings;
import Vino.Checkpoints.Checkpoint;

struct FMoleChaseManagerReplicatedPosition
{
	FVector Position;
	FVector Velocity;

	void Init(FVector Pos)
	{
		Position = Pos;
		Velocity = FVector::ZeroVector;
	}

	void UpdatePosition(float DeltaTime)
	{
		Position += Velocity * DeltaTime;
	}
}

class AMoleChaseManager : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent ManagerMesh;

	UPROPERTY(EditInstanceOnly)
	ACheckpoint MovableCheckpoint;
	
	const float MoveSpeedLerpAcceleration = 50.f;
	const float TimeDiliationAcceleration = 0.035f;
	const float MoleSpeedAccelerationMultiplier = 0.3f;

	bool Active = false;

	TArray<AChasingMole> CurrentMoles;
	AChasingMole MainMole;
	ASplineActor RubberBandingSpline;

	private bool bHasCustomMoveSettings = false;
	private TArray<float> TargetMovementSpeed;
	private TArray<float> TargetTimeDilation;
	private TArray<FMoleChaseManagerReplicatedPosition> ReplicatedPosition;
	private TArray<int> LastNetworkValidationIndex;

	// Mole area settings
	FHazeMinMax MoleRubberBandingDistance;
	FHazeMinMax MoleRubberBandingSpeed;
	float MoleRubberBandingAnimationMultiplier = 1;

	// Player area settings
	float PlayerBaseSpeed;
	FHazeMinMax PlayerRubberBandingDistance;
	FHazeMinMax PlayerRubberBandingSpeed;
	FHazeMinMax PlayerRubberBandingTimeDilation;
	bool bAllowTimeDilation = true;

	#if EDITOR
	// So we can tweak the values in runtime
	private	FString DebugSettingsName;
	private int DebugChaseSettingsIndex;
	
	#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// One for each player
		for(int i = 0; i < 2; ++i)
		{
			TargetMovementSpeed.Add(1.f);
			TargetTimeDilation.Add(1.f);
			ReplicatedPosition.Add(FMoleChaseManagerReplicatedPosition());
			LastNetworkValidationIndex.Add(0);
		}
		
		SetActorTickEnabled(false);
	}


	//NetWorked via ProgressPoints & PlayerTrigger
	UFUNCTION()
	void ActivateManager()
	{
		Active = true;
		Game::Cody.BlockCapabilities(n"Vine", this);
		Game::May.BlockCapabilities(n"WaterHose", this);
		SetActorTickEnabled(true);

		FOnRespawnTriggered OnRespawn;
		OnRespawn.BindUFunction(this, n"PlayerRespawned");
		BindOnPlayerRespawnedEvent(OnRespawn);
	}

	//Networked via PlayerTrigger
	UFUNCTION()
	void DeactiveManager()
	{
		if(Active != true)
			return;

		Active = false;
		SetActorTickEnabled(false);

		if(bHasCustomMoveSettings)
			ClearCustomMoveSettings();

		Game::Cody.UnblockCapabilities(n"Vine", this);
		Game::May.UnblockCapabilities(n"WaterHose", this);
		UnbindOnPlayerRespawnedEvent(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerRespawned(AHazePlayerCharacter Player)
	{
		ReplicatedPosition[int(Player.Player)].Init(Player.GetActorLocation());
	}

	void ClearCustomMoveSettings()
	{
		bHasCustomMoveSettings = false;
		auto Players = Game::GetPlayers();
		for(auto Player : Players)
		{
			//USprintSettings::ClearMoveSpeed(Player, this);
			//UMovementSettings::ClearHorizontalAirSpeed(Player, this);
			ClearActorTimeDilation(Player, this);
			Player.ClearSettingsByInstigator(this);
		}
	}

	UFUNCTION()
	void SetRubberBandingSpline(ASplineActor Spline)
	{
		RubberBandingSpline = Spline;
	}

	UFUNCTION()
	void TurnOffSpeedEffect()
	{
		//Game::GetCody().BlockCapabilities(n"SpeedEffect", this);
		//Game::GetMay().BlockCapabilities(n"SpeedEffect", this);
	}

	UFUNCTION()
	void ChangeMoleTargets(TArray<AChasingMole> Moles)
	{
		if(MainMole != nullptr)
			MainMole.bIsMainMole = false;
			
		CurrentMoles.Empty();

		CurrentMoles = Moles;
		MainMole = Moles.Last();
		MainMole.bIsMainMole = true;
		//SetRubberBandingSpline(MainMole.SplineToFollow);
	}

	UFUNCTION()
	void AddMoleTarget(TArray<AChasingMole> Moles)
	{
		for (AChasingMole Mole : Moles)
		{
			CurrentMoles.AddUnique(Mole);
		}
	}

	UFUNCTION()
	void EmptyMoleTargets()
	{
		CurrentMoles.Empty();
	}


	UFUNCTION()
	void ChangeValuesIntoNormal()
	{
		#if EDITOR
		DebugSettingsName = "Normal";
		DebugChaseSettingsIndex = 0;
		#endif

		MoleRubberBandingSpeed = FHazeMinMax(800.f, 1800.f);
		MoleRubberBandingDistance = FHazeMinMax(500.f, 4000.f);
		MoleRubberBandingAnimationMultiplier = 1.f;

		PlayerBaseSpeed = 1150.f;
		PlayerRubberBandingSpeed = FHazeMinMax(700.f, 1500);
		PlayerRubberBandingDistance = FHazeMinMax(100.f, 1000.f);
		PlayerRubberBandingTimeDilation = FHazeMinMax(0.93f, 1.06f);
		bAllowTimeDilation = true;
	}

	UFUNCTION()
	void ChangeValuesIntoTopDown()
	{
		#if EDITOR
		DebugSettingsName = "TopDown";
		DebugChaseSettingsIndex = 1;
		#endif
		
		MoleRubberBandingSpeed = FHazeMinMax(1000.f, 2000.f);
		MoleRubberBandingDistance = FHazeMinMax(1500.f, 3000.f);
		MoleRubberBandingAnimationMultiplier = 1.f;

		PlayerBaseSpeed = 1200.f;
		PlayerRubberBandingSpeed = FHazeMinMax(1100.f, 1550);
		PlayerRubberBandingDistance = FHazeMinMax(100.f, 1000.f);
		PlayerRubberBandingTimeDilation = FHazeMinMax(0.93f, 1.06f);
		bAllowTimeDilation = true;
	}

	UFUNCTION()
	void ChangeValuesIntoTopDownMaze()
	{
		#if EDITOR
		DebugSettingsName = "TopDownMaze";
		DebugChaseSettingsIndex = 2;
		#endif
		
		MoleRubberBandingSpeed = FHazeMinMax(300.f, 1500.f);
		MoleRubberBandingDistance = FHazeMinMax(2000.f, 3000.f);
		MoleRubberBandingAnimationMultiplier = 1.f;

		PlayerBaseSpeed = 1200.f;
		PlayerRubberBandingSpeed = FHazeMinMax(1100.f, 1450);
		PlayerRubberBandingDistance = FHazeMinMax(100.f, 1000.f);
		PlayerRubberBandingTimeDilation = FHazeMinMax(0.93f, 1.06f);
		bAllowTimeDilation = true;
	}


	UFUNCTION()
	void ChangeValuesInto2D()
	{
		#if EDITOR
		DebugSettingsName = "2D";
		DebugChaseSettingsIndex = 3;
		#endif

		MoleRubberBandingSpeed = FHazeMinMax(1000.f, 2300.f);
		MoleRubberBandingDistance = FHazeMinMax(900.f, 3600.f);
		MoleRubberBandingAnimationMultiplier = 1.f;

		PlayerBaseSpeed = 1350.f;
		PlayerRubberBandingSpeed = FHazeMinMax(1200.f, 1500);
		PlayerRubberBandingDistance = FHazeMinMax(100.f, 1000.f);
		PlayerRubberBandingTimeDilation = FHazeMinMax(0.97f, 1.03f);
		bAllowTimeDilation = true;
	}


	UFUNCTION()
	void ChangeValuesInto2DGoldRoom()
	{
		#if EDITOR
		DebugSettingsName = "2D";
		DebugChaseSettingsIndex = 4;
		#endif

		MoleRubberBandingSpeed = FHazeMinMax(1150.f, 1800.f);
		MoleRubberBandingDistance = FHazeMinMax(1000.f, 2750.f);
		MoleRubberBandingAnimationMultiplier = 1.f;

		PlayerBaseSpeed = 1350.f;
		PlayerRubberBandingSpeed = FHazeMinMax(1200.f, 1500);
		PlayerRubberBandingDistance = FHazeMinMax(100.f, 1000.f);
		PlayerRubberBandingTimeDilation = FHazeMinMax(0.97f, 1.03f);
		bAllowTimeDilation = true;
	}

	UFUNCTION()
	void ChangeValuesInto2DEnding()
	{
		#if EDITOR
		DebugSettingsName = "2D Ending";
		DebugChaseSettingsIndex = 5;
		#endif

		MoleRubberBandingSpeed = FHazeMinMax(400.f, 1000.f);
		MoleRubberBandingDistance = FHazeMinMax(1200.f, 1450.f);
		MoleRubberBandingAnimationMultiplier = 1.f;

		PlayerBaseSpeed = 1350.f;
		PlayerRubberBandingSpeed = FHazeMinMax(1200.f, 1500);
		PlayerRubberBandingDistance = FHazeMinMax(100.f, 1000.f);
		PlayerRubberBandingTimeDilation = FHazeMinMax(1.f, 1.f);
		bAllowTimeDilation = false;

		auto Players = Game::GetPlayers();
		for(auto Player : Players)
		{
			ClearActorTimeDilation(Player, this);
		}
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(MainMole != nullptr && RubberBandingSpline != nullptr)
		{
			if(!bHasCustomMoveSettings)
			{
				// We will use a custom location calculator to make the players more accurate to eachother
				auto Players = Game::GetPlayers();
				for(auto Player : Players)
				{	
					ReplicatedPosition[int(Player.Player)].Init(Player.GetActorLocation());
				}	
			}

			// Update all the values in the editor so they can be changed in runtime
			#if EDITOR

			if(DebugChaseSettingsIndex == 0)
				ChangeValuesIntoNormal();
			else if(DebugChaseSettingsIndex == 1)
				ChangeValuesIntoTopDown();
			else if(DebugChaseSettingsIndex == 2)
				ChangeValuesIntoTopDownMaze();
			else if(DebugChaseSettingsIndex == 3)
				ChangeValuesInto2D();
			else if(DebugChaseSettingsIndex == 4)
				ChangeValuesInto2DGoldRoom();
			else if(DebugChaseSettingsIndex == 5)
				ChangeValuesInto2DEnding();


			#endif

			bHasCustomMoveSettings = true;
			CalculateRubberBanding(DeltaTime);
		}
		else if(bHasCustomMoveSettings)
		{
			ClearCustomMoveSettings();
		}
	}

	void CalculateRubberBanding(float DeltaTime)
	{
		auto Cody = Game::Cody;
		auto May = Game::May;

		const bool bCodyIsDead = Cody.IsPlayerDead();
		const bool bMayIsDead = May.IsPlayerDead();

		if(bCodyIsDead && bMayIsDead)
		{
			//DEBUG
		#if EDITOR
			if(bHazeEditorOnlyDebugBool)
			{
				Print("BOTH PLAYERS ARE DEAD", 0.f);
			}	
		#endif

			return;
		}

		EHazePlayer FirstPlayer = EHazePlayer::MAX;
		EHazePlayer SecondPlayer = EHazePlayer::MAX;
		TArray<AHazePlayerCharacter> ControlSidePlayers;

		float DistanceFromEachOther = 0;
		FVector PlayerMedianPosition;

		if(bCodyIsDead)
		{
			PlayerMedianPosition = May.GetActorLocation();
			FirstPlayer = EHazePlayer::May;
			SecondPlayer = EHazePlayer::Cody;
			if(May.HasControl())
				ControlSidePlayers.Add(May);
		}
		else if(bMayIsDead)
		{
			PlayerMedianPosition = Cody.GetActorLocation();
			FirstPlayer = EHazePlayer::Cody;
			SecondPlayer = EHazePlayer::May;
			if(Cody.HasControl())
				ControlSidePlayers.Add(Cody);
		}
		else
		{
			FVector CodyLocation = Cody.GetActorLocation();
			FVector MayLocation = May.GetActorLocation();
		
			// Player Replication
			if(May.HasControl())
			{
				NetSendMedianLocation(LastNetworkValidationIndex[int(May.Player)] + 1, May, MayLocation, May.MovementComponent.GetVelocity());
				ControlSidePlayers.Add(May);
			}
			else
			{
				ReplicatedPosition[int(May.Player)].UpdatePosition(DeltaTime);
			}
	
			if(Cody.HasControl())
			{
				NetSendMedianLocation(LastNetworkValidationIndex[int(Cody.Player)] + 1, Cody, CodyLocation, Cody.MovementComponent.GetVelocity());
				ControlSidePlayers.Add(Cody);
			}
			else
			{
				ReplicatedPosition[int(Cody.Player)].UpdatePosition(DeltaTime);
			}
	
		
			// Mole characteristics
			const FHazeSplineSystemPosition MoleSplinePosition = RubberBandingSpline.Spline.GetPositionClosestToWorldLocation(MainMole.GetActorLocation());
			const FVector MainMoleCurrentLocation = MoleSplinePosition.GetWorldLocation();
			const float CodyDistanceFromMainMole =  (CodyLocation - MainMoleCurrentLocation).Size();
			const float MayDistanceFromMainMole =  (MayLocation - MainMoleCurrentLocation).Size();

			// Player Characteristics
			PlayerMedianPosition = (ReplicatedPosition[0].Position + ReplicatedPosition[1].Position) * 0.5f;
			DistanceFromEachOther = FMath::Max((MayLocation - CodyLocation).Size() - PlayerRubberBandingDistance.Min, 0.f);

			if(CodyDistanceFromMainMole >= MayDistanceFromMainMole)
			{
				FirstPlayer = EHazePlayer::Cody;
				SecondPlayer = EHazePlayer::May;
			}
			else
			{
				FirstPlayer = EHazePlayer::May;
				SecondPlayer = EHazePlayer::Cody;
			}
		}

		// Update the respawn position
		float Distance = RubberBandingSpline.Spline.GetDistanceAlongSplineAtWorldLocation(PlayerMedianPosition);
		Distance += Network::GetPingRoundtripSeconds() * 0.5f * PlayerBaseSpeed;
		Distance += PlayerBaseSpeed * 0.5f;
		FVector MovableCheckpointPosition = RubberBandingSpline.Spline.GetLocationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
		MovableCheckpoint.SetActorLocation(MovableCheckpointPosition);

		if(bCodyIsDead or bMayIsDead or DistanceFromEachOther < KINDA_SMALL_NUMBER)
		{
			TargetTimeDilation[0] = 1.f;
			TargetMovementSpeed[0] = PlayerBaseSpeed;

			TargetTimeDilation[1] = 1.f;
			TargetMovementSpeed[1] = PlayerBaseSpeed;
		}
		else
		{
			// First Player
			{
				const float DistanceToMedian = Game::GetPlayer(FirstPlayer).GetActorLocation().Distance(PlayerMedianPosition);
				const float RubberBandAlpha = FMath::Min(DistanceToMedian / (PlayerRubberBandingDistance.Max - PlayerRubberBandingDistance.Min), 1.f);
				TargetMovementSpeed[int(FirstPlayer)] = FMath::Lerp(PlayerBaseSpeed, PlayerRubberBandingSpeed.Min, FMath::EaseIn(0.f, 1.f, RubberBandAlpha, 1.5f));
				TargetTimeDilation[int(FirstPlayer)] = PlayerRubberBandingTimeDilation.Min;
			}
	
			// Second Player
			{
				const float DistanceToMedian = Game::GetPlayer(SecondPlayer).GetActorLocation().Distance(PlayerMedianPosition);
				const float RubberBandAlpha = FMath::Min(DistanceToMedian / (PlayerRubberBandingDistance.Max - PlayerRubberBandingDistance.Min), 1.f);
				TargetMovementSpeed[int(SecondPlayer)] = FMath::Lerp(PlayerBaseSpeed, PlayerRubberBandingSpeed.Max, FMath::EaseOut(0.f, 1.f, RubberBandAlpha, 1.5f));
				TargetTimeDilation[int(SecondPlayer)] = PlayerRubberBandingTimeDilation.Max;
			}		
		}

		// Change the movespeed depening on the current offset from eachother
		for(auto Player : ControlSidePlayers)
		{
			int i = int(Player.Player);
			auto SprintSettings = USprintSettings::GetSettings(Player);

			float CurrentSpeed = SprintSettings.MoveSpeed;
			float TargetSpeed = TargetMovementSpeed[i];
			CurrentSpeed = FMath::FInterpConstantTo(CurrentSpeed, TargetSpeed, DeltaTime, MoveSpeedLerpAcceleration);
	
			USprintSettings::SetMoveSpeed(Player, CurrentSpeed, this);
			UMovementSettings::SetHorizontalAirSpeed(Player, CurrentSpeed, this);

			float NewTimeDiliation = FMath::FInterpConstantTo(Player.CustomTimeDilation, TargetTimeDilation[i], DeltaTime, TimeDiliationAcceleration);
			if(bAllowTimeDilation)
				ModifyActorTimeDilation(Player, NewTimeDiliation, this, false);
		}

		// Update active moles
		const FVector TargetPlayerPos = PlayerMedianPosition;
		for (AChasingMole Mole : CurrentMoles)
		{
			const float MoleBaseSpeedTemp = Mole.BaseSpeed;
			const FVector MoleCurrentLocation = Mole.GetActorLocation();
			const float TargetDistanceFromMole = FMath::Max((TargetPlayerPos - MoleCurrentLocation).Size() - MoleRubberBandingDistance.Min, 0.f);
			const float RubberBandAlpha = FMath::Min(TargetDistanceFromMole / (MoleRubberBandingDistance.Max - MoleRubberBandingDistance.Min), 1.f);
			const float TargetSpeed = FMath::Lerp(MoleRubberBandingSpeed.Min, MoleRubberBandingSpeed.Max, RubberBandAlpha);
			
			if(TargetSpeed > Mole.DesiredFollowSpeed)
				Mole.DesiredFollowSpeed = FMath::FInterpTo(Mole.DesiredFollowSpeed, TargetSpeed, DeltaTime, 25.f);
			else
				Mole.DesiredFollowSpeed = FMath::FInterpTo(Mole.DesiredFollowSpeed, TargetSpeed, DeltaTime, 50.f);

			Mole.AnimationMultiplier = FMath::Lerp(Mole.AnimationMultiplier, MoleRubberBandingAnimationMultiplier, DeltaTime * 0.05f);

			// Check if the player collides with the mole
			Mole.UpdateDeathTriggers(ControlSidePlayers);
		}
	
		
		// DEBUG
		#if EDITOR
		if(bHazeEditorOnlyDebugBool)
		{
			for(auto Player : ControlSidePlayers)
			{
				const FLinearColor Color = Player.Player == EHazePlayer::May ? FLinearColor::LucBlue : FLinearColor::Green;
				const FHazeSplineSystemPosition MoleSplinePosition = RubberBandingSpline.Spline.GetPositionClosestToWorldLocation(MainMole.GetActorLocation());
				const FVector MainMoleCurrentLocation = MoleSplinePosition.GetWorldLocation();
				auto SprintSettings = USprintSettings::GetSettings(Player);

				PrintToScreen("\n", Color = Color);
		
				if(CurrentMoles.Num() > 0)
				{
					for (AChasingMole Mole : CurrentMoles)
					{
						PrintToScreen("  Mole : " + Mole.GetName() + " Speed: " + TrimFloatValue(Mole.DesiredFollowSpeed, true), Color = Color);
						Mole.DrawDebug();
					}

					PrintToScreen("\nMole Settings\n" 
						+ "(Speed Clamp: " + TrimFloatValue(MoleRubberBandingSpeed.Min, true) + " | " + TrimFloatValue(MoleRubberBandingSpeed.Max, true) + ")"
						+ " | (Distance Clamp: " + TrimFloatValue(MoleRubberBandingDistance.Min, true) + " | " + TrimFloatValue(MoleRubberBandingDistance.Max, true) + ")"
						, Color = Color);
				}

	
				PrintToScreen("  DistanceFromEachOther: " + TrimFloatValue(DistanceFromEachOther, true)
				+ " | (Clamp " + TrimFloatValue(PlayerRubberBandingDistance.Min, true)
				+ " | " + TrimFloatValue(PlayerRubberBandingDistance.Max, true) + ")"
				, Color = Color);
				PrintToScreen("  DistanceFromMainMole: " + TrimFloatValue((Player.GetActorLocation() - MainMoleCurrentLocation).Size(), true), Color = Color);
				PrintToScreen("  TimeDilation:  " +  TrimFloatValue(Player.CustomTimeDilation, true), Color = Color);
				PrintToScreen("  SprintSpeed:  " 
				+ TrimFloatValue(SprintSettings.MoveSpeed, true) 
				+ " (Clamp " + TrimFloatValue(PlayerRubberBandingSpeed.Min, true) 
				+ " | " + TrimFloatValue(PlayerRubberBandingSpeed.Max, true) + ")"
				
				, Color = Color);

				if(!Network::IsNetworked())
					PrintToScreen("Player" + Player.GetName(), Color = Color);
			}

			const FLinearColor FirstPlaceColor = FirstPlayer == EHazePlayer::May ? FLinearColor::LucBlue : FLinearColor::Green;
			PrintToScreen("First Place: "+ Game::GetPlayer(FirstPlayer).GetName() + "\n", Color = FirstPlaceColor);
	
		
			FLinearColor MedianLocationColor;
			if(!Network::IsNetworked())
				MedianLocationColor = FLinearColor::White;
			else if(Game::GetMay().HasControl())
				MedianLocationColor = FLinearColor::LucBlue;
			else
				MedianLocationColor = FLinearColor::Green;

			PrintToScreen("Settings: "+ DebugSettingsName, Color = MedianLocationColor);
			System::DrawDebugSphere(PlayerMedianPosition, 100, LineColor = MedianLocationColor);
		}	
		#endif
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSendMedianLocation(int NetworkValidation, AHazePlayerCharacter Player, FVector Location, FVector Velocity)
	{
		const int i = int(Player.Player);
		if(Player.HasControl())
		{
			LastNetworkValidationIndex[i] = NetworkValidation;
			ReplicatedPosition[i].Position = Location;
			ReplicatedPosition[i].Velocity = Velocity;
		}
		else
		{
			// Unreliable can be out of order
			if(LastNetworkValidationIndex[i] > NetworkValidation)
				return;

			LastNetworkValidationIndex[i] = NetworkValidation;
			const float Ping = Network::GetPingRoundtripSeconds() * 0.5f;
			ReplicatedPosition[i].Position = Location;
			ReplicatedPosition[i].Position += Velocity * Ping;
			ReplicatedPosition[i].Velocity = Velocity;
		}
	}
}
