import Cake.LevelSpecific.Garden.MiniGames.Swings.GardenSwingPlayerComponent;

class UGardenSwingingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GardenSwings");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AGardenSwingsActor Swings;

	AHazePlayerCharacter May;
	AHazePlayerCharacter Cody;

	UGardenSingleSwingComponent MaySwing;
	UGardenSingleSwingComponent CodySwing;

	UGardenSwingPlayerComponent MaySwingComp;
	UGardenSwingPlayerComponent CodySwingComp;

	bool bMaySwingStill = false;
	bool bCodySwingStill = false;

	bool bMayTauntPlayed = false;
	bool bCodyTauntPlayed = false;

	bool bRoundTauntPlayed = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Swings = Cast<AGardenSwingsActor>(Owner);
		MaySwing = Swings.MaySwing;
		CodySwing = Swings.CodySwing;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(MaySwing.CurrentPlayer == nullptr && CodySwing.CurrentPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate;	

		if(!MaySwing.bSwinging && !CodySwing.bSwinging)
			return EHazeNetworkActivation::DontActivate;

		if(!Swings.bMiniGameIsOn)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!Swings.bMiniGameIsOn)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!MaySwing.bPlayerHasJumped || !CodySwing.bPlayerHasJumped)
			return EHazeNetworkDeactivation::DontDeactivate;
			
		if(!bMaySwingStill || !bCodySwingStill)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		May = MaySwing.CurrentPlayer;
		Cody = CodySwing.CurrentPlayer;

		MaySwingComp = UGardenSwingPlayerComponent::Get(May);
		CodySwingComp = UGardenSwingPlayerComponent::Get(Cody);
		
		SetSwingStartValues(MaySwing);
		SetSwingStartValues(CodySwing);
	}

	UFUNCTION()
	void SetSwingStartValues(UGardenSingleSwingComponent SingleSwing)
	{
		SingleSwing.DesiredAngle = 10.0f;
		SingleSwing.LastFrameTimeSin = 0.0f;
		SingleSwing.TargetAngle = 10.0f;
		SingleSwing.LastFrameAngle = 0.0f;
		SingleSwing.CurrentAngle = 0.0f;
		
		SingleSwing.Angle = 0.0f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(!bMaySwingStill)
		{
			MaySwing.DesiredAngle = 0.0f;
			MaySwing.LastFrameTimeSin = 0.0f;
			MaySwing.TargetAngle = 0.0f;
			MaySwing.LastFrameAngle = 0.0f;
			MaySwing.CurrentAngle = 0.0f;

			MaySwing.Angle = 0.0f;

			Swings.MaySwingSyncFloat.Value = 0.0f;
		}
		else if(!bCodySwingStill)
		{
			CodySwing.DesiredAngle = 0.0f;
			CodySwing.LastFrameTimeSin = 0.0f;
			CodySwing.TargetAngle = 0.0f;
			CodySwing.LastFrameAngle = 0.0f;
			CodySwing.CurrentAngle = 0.0f;

			CodySwing.Angle = 0.0f;

			Swings.CodySwingSyncFloat.Value = 0.0f;
		}

		bMaySwingStill = false;
		bCodySwingStill = false;

		bCodyTauntPlayed = false;
		bMayTauntPlayed = false;
		bRoundTauntPlayed = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Game::GetCody().HasControl())
		{
			if(!CodySwing.bPlayerHasJumped)
			{
				UpdateSwingWithPlayerInput(DeltaTime, CodySwing, Cody, CodySwingComp);

				if(CodySwing.DesiredAngle >= Swings.MaxPitchValue && !bCodyTauntPlayed && !bRoundTauntPlayed)
				{
					NetPlayVOTaunt(Game::GetCody());
					bCodyTauntPlayed = true;
				}
			}
			else if(!bCodySwingStill)
			{
				StopSwing(DeltaTime, CodySwing);
			}
			
			Swings.CodySwingSyncFloat.Value = CodySwing.CurrentAngle;
		}
		else
		{
			RemoteSwing(CodySwing, Swings.CodySwingSyncFloat);
		}

		if(Game::GetMay().HasControl())
		{
			if(!MaySwing.bPlayerHasJumped)
			{
				UpdateSwingWithPlayerInput(DeltaTime, MaySwing, May, MaySwingComp);	

				if(MaySwing.DesiredAngle >= Swings.MaxPitchValue && !bMayTauntPlayed && !bRoundTauntPlayed)
				{
					NetPlayVOTaunt(Game::GetMay());
					bMayTauntPlayed = true;
				}

			}
			else if(!bMaySwingStill)
			{
				StopSwing(DeltaTime, MaySwing);	
			}
				
			Swings.MaySwingSyncFloat.Value = MaySwing.CurrentAngle;
		}
		else
		{
			RemoteSwing(MaySwing, Swings.MaySwingSyncFloat);
		}
	}

	UFUNCTION()
	void UpdateSwingWithPlayerInput(float DeltaTime, UGardenSingleSwingComponent Swing, AHazePlayerCharacter Player, UGardenSwingPlayerComponent SwingComp)
	{
		float SinTime = FMath::Sin(System::GetGameTimeInSeconds() * 1.35f);

		float Force = SwingComp.RawInput.Y;
		float Magnifier = FMath::GetMappedRangeValueClamped(FVector2D(10, Swings.MaxPitchValue), FVector2D(15, 10), Swing.DesiredAngle);
		
		if(SinTime < Swing.LastFrameTimeSin)
			Force *= -1;

		if(FMath::IsNearlyZero(SinTime, 0.05f))
		{
			Swing.TargetAngle = Swing.DesiredAngle;
		}

		Swing.DesiredAngle += Force * DeltaTime * Magnifier;
		Swing.DesiredAngle = FMath::Clamp(Swing.DesiredAngle, 10.0f, Swings.MaxPitchValue);
		
		Swing.CurrentAngle = FMath::FInterpTo(Swing.CurrentAngle, Swing.TargetAngle, DeltaTime, 1.0f);
		Swing.Angle = SinTime * Swing.CurrentAngle;

		Swing.LastFrameTimeSin = SinTime;
		Swing.LastFrameAngle = Swing.Angle;
	}

	UFUNCTION()
	void StopSwing(float DeltaTime, UGardenSingleSwingComponent Swing)
	{
		float SinTime = FMath::Sin(System::GetGameTimeInSeconds() * 1.35f);

		Swing.TargetAngle = 0.0f;
		
		Swing.CurrentAngle = FMath::FInterpTo(Swing.CurrentAngle, Swing.TargetAngle, DeltaTime, 0.75f);
		Swing.Angle = SinTime * Swing.CurrentAngle;

		if(FMath::IsNearlyEqual(Swing.Angle, Swing.LastFrameAngle, 0.05f) && FMath::IsNearlyZero(Swing.Angle, 0.02f))
		{
			Swing.Angle = 0.0f;
			if(Swing == Swings.MaySwing)
				bMaySwingStill = true;
			else 
				bCodySwingStill = true;
		}

		Swing.LastFrameTimeSin = SinTime;
		Swing.LastFrameAngle = Swing.Angle;
	}

	UFUNCTION()
	void RemoteSwing(UGardenSingleSwingComponent Swing, UHazeSmoothSyncFloatComponent SyncFloat)
	{
		float SinTime = FMath::Sin(System::GetGameTimeInSeconds() * 1.35f);
		Swing.CurrentAngle = SyncFloat.Value;
		
		Swing.Angle = SinTime * Swing.CurrentAngle;
		Swing.LastFrameAngle = Swing.Angle;

		if(FMath::IsNearlyEqual(Swing.Angle, Swing.LastFrameAngle, 0.05f) && FMath::IsNearlyZero(Swing.Angle, 0.02f))
		{
			Swing.Angle = 0.0f;

			if(Swing == Swings.MaySwing)
				bMaySwingStill = true;
			else 
				bCodySwingStill = true;
		}
	}

	UFUNCTION(NetFunction)
	void NetPlayVOTaunt(AHazePlayerCharacter Player)
	{
		bRoundTauntPlayed = true;
		Swings.MinigameComp.PlayTauntAllVOBark(Player);
	}
}