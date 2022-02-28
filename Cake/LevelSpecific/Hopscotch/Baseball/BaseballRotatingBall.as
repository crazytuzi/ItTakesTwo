
event void FOnBallMayImpacted(bool Front);
event void FOnBallCodyImpacted(bool Front);
event void FOnSpawnHitEffect();
class ABaseballRotatingBall : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent StaticMesh;
	UPROPERTY(DefaultComponent)
	USceneComponent BaseballBatImpactLocation;
	UPROPERTY(DefaultComponent, Attach = BaseballBatImpactLocation)
	USphereComponent BaseballBatSphereComponent;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent BaseballSyncRotation;
	default BaseballSyncRotation.NumberOfSyncsPerSecond = 15;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent BallHazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayRotatingBallAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopRotatingBallLoopsAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HitBallAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HitBallBackAudioEvent;

	UPROPERTY()
	FOnBallMayImpacted OnBallMayImpacted;
	UPROPERTY()
	FOnBallCodyImpacted OnBallCodyImpacted;
	UPROPERTY()
	FOnSpawnHitEffect OnSpawnHitEffect;

	float TargetPitchValue = 0;
	float RotateTargetValue;
	FHazeAcceleratedFloat AcceleratedFloat;
	float fLerp;

	UPROPERTY()
	bool bLeftP1;
	float RotationVelocity = 1;
	float PitchValue;
	float FuturePitch;
	bool bHasBeenImpacted = false;
	bool bRecentlyImpacted = false;
	bool RotationDirection;
	bool bAcceleratedFloatSet = false;
	bool bCountdownStarted = false;
	float NormalizedRotationVelocity;
	AHazePlayerCharacter ControlSidePlayer;
	float BallStartRotation;
	bool bMiniGameFinished = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BallStartRotation = GetActorRotation().Yaw;
		if(bLeftP1 == true)
		{
			RotationDirection = true;
		}
		else
		{
			RotationDirection = false;
		}

		if(bLeftP1)
		{
			SetControlSide(Game::May);
			ControlSidePlayer = Game::GetMay();
			BaseballSyncRotation.OverrideControlSide(ControlSidePlayer);
		}
		else
		{

			SetControlSide(Game::Cody);
			ControlSidePlayer = Game::GetCody();
			BaseballSyncRotation.OverrideControlSide(ControlSidePlayer);
		}

		BaseballSyncRotation.Value = GetActorRotation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		if(bHasBeenImpacted == false)
		{
			if(!bCountdownStarted)
				return;

			if(ControlSidePlayer.HasControl())
			{
				if(!bAcceleratedFloatSet)
				{
					AcceleratedFloat.Value = GetActorRotation().Yaw;
					bAcceleratedFloatSet = true;
				}
				
				AcceleratedFloat.SpringTo(BallStartRotation, 1, 0.85f, DeltaSeconds);
				BaseballSyncRotation.Value = GetActorRotation();;
				TargetPitchValue = AcceleratedFloat.Value;
				FHitResult Hit;
				SetActorRotation(FRotator(0, TargetPitchValue, 0));

				if(FMath::IsNearlyEqual(AcceleratedFloat.Value, BallStartRotation, 1.0f))
				{
					NormalizedRotationVelocity = 0;
				}
				else
				{
					NormalizedRotationVelocity = 0.15f;
				}
				//PrintToScreen("NormalizedRotationVelocity PreGame" + NormalizedRotationVelocity);
			}
			else
			{
				SetActorRotation(FRotator(BaseballSyncRotation.Value));
			}
		}
		else
		{
			if(!bMiniGameFinished)
			{
				if(RotationVelocity >= 600)
				{
					RotationVelocity -= 3.0f * (DeltaSeconds * 62);
				}
				if(RotationVelocity >= 500 && RotationVelocity < 600)
				{
					RotationVelocity -= 2.5f * (DeltaSeconds * 62);
				}
				if(RotationVelocity >= 400 && RotationVelocity < 500)
				{
					RotationVelocity -= 2.2f * (DeltaSeconds * 62);
				}
				if(RotationVelocity >= 300 && RotationVelocity < 400)
				{
					RotationVelocity -= 1.75f * (DeltaSeconds * 62);
				}
				if(RotationVelocity >= 200 && RotationVelocity < 300)
				{
					RotationVelocity -= 1.5f * (DeltaSeconds * 62);
				}
				if(RotationVelocity >= 110 && RotationVelocity < 200)
				{
					RotationVelocity -= 1.25f * (DeltaSeconds * 62);
				}
				if(RotationVelocity >= 90 && RotationVelocity < 110)
				{	
					RotationVelocity -= 0.1f * (DeltaSeconds * 62);
				}
			}
			else
			{
				if(RotationVelocity > 100)
				{
					RotationVelocity -= 0.75f * (DeltaSeconds * 62);
				}
				else if(RotationVelocity > 15.f && RotationVelocity <= 100)
				{
					RotationVelocity -= 0.5f * (DeltaSeconds * 62);
				}
				else if(RotationVelocity > 1.0f && RotationVelocity <= 15)
				{
					RotationVelocity -= 0.15f  * (DeltaSeconds * 62);
				}
				else if(RotationVelocity <= 1.0f)
				{
					RotationVelocity = 0;
				}
			}

			if(RotationDirection == true)
			{
				FuturePitch = GetActorRotation().Pitch - RotationVelocity * DeltaSeconds;
			}
			else
			{
				FuturePitch = GetActorRotation().Pitch + RotationVelocity * DeltaSeconds;
			}

			BaseballSyncRotation.Value = GetActorRotation();;
			AddActorLocalRotation(FRotator(0, FuturePitch, 0));

			NormalizedRotationVelocity = RotationVelocity/700;
			BallHazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Minigames_Baseball_RotatingVelocity", NormalizedRotationVelocity);
			//PrintToScreen("NormalizedRotationVelocity DuringGame" + NormalizedRotationVelocity);
		}



		//PrintToScreen("RotationVelocity " + RotationVelocity);
		//PrintToScreen("bHasBeenImpacted " + bHasBeenImpacted);
		//PrintToScreen("bRecentlyImpacted " + bRecentlyImpacted);
		//PrintToScreen("DeacclerationMultiplier " + DeacclerationMultiplier);
	}

	UFUNCTION()
	void Impacted(bool Front)
	{
		if(ControlSidePlayer.HasControl())
		{
			NetImpacted(Front);
		}
	}

	UFUNCTION(NetFunction)
	void NetImpacted(bool Front)
	{
		if(bRecentlyImpacted == true)
			return;

		bRecentlyImpacted = true;
		if(bLeftP1 == true)
		{
			if(Front == true)
			{
				RotationDirection = true;
				BallHazeAkComp.HazePostEvent(HitBallAudioEvent);
			}
			else
			{
				RotationDirection = false;
				BallHazeAkComp.HazePostEvent(HitBallBackAudioEvent);
			}
		}
		else
		{
			if(Front == true)
			{
				RotationDirection = false;
				BallHazeAkComp.HazePostEvent(HitBallAudioEvent);
			}
			else
			{
				RotationDirection = true;
				BallHazeAkComp.HazePostEvent(HitBallBackAudioEvent);
			}
		}

		if(!bHasBeenImpacted)
		{
			RotationVelocity += 270;
			bHasBeenImpacted = true;
			if(ControlSidePlayer.HasControl())
			{
				OnSpawnHitEffect.Broadcast();
			}
		}
		else
		{
			if(Front == true)
			{
				if(RotationVelocity > 600)
					RotationVelocity += 130 - (RotationVelocity * 0.05);
				else if(RotationVelocity >= 400 && RotationVelocity < 600)
					RotationVelocity += 150 - (RotationVelocity * 0.05);
				else if(RotationVelocity >= 200 && RotationVelocity < 400)
					RotationVelocity += 160 - (RotationVelocity * 0.05);
				else if(RotationVelocity < 200)
					RotationVelocity += 205 - (RotationVelocity * 0.05);

				if(ControlSidePlayer.HasControl())
				{
					OnSpawnHitEffect.Broadcast();
				}
			}
			else
			{
				if(RotationVelocity > 400)
					RotationVelocity = RotationVelocity/1.85;
				else if(RotationVelocity >= 200 && RotationVelocity < 400)
					RotationVelocity = RotationVelocity/1.5;
				else if(RotationVelocity < 200)
					RotationVelocity = RotationVelocity/1.25f;
			}
		}

		if(bLeftP1 == true)
		{
			OnBallMayImpacted.Broadcast(Front);
		}
		if(bLeftP1 == false)
		{
			OnBallCodyImpacted.Broadcast(Front);
		}

		System::SetTimer(this, n"ResetRecentlyImpacted", 0.3f, false);
	}

	UFUNCTION()
	void ResetRecentlyImpacted()
	{
		bRecentlyImpacted = false;
	}
}
