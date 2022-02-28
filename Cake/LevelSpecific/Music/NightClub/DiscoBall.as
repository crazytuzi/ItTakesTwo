import Peanuts.Spline.SplineActor;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.Components.FloorJumpCallbackComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Movement.Components.MovementComponent;
import Peanuts.Foghorn.FoghornStatics;

event void FDiscoBallSignature();

class ANightclubDiscoBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Sphere;

	UPROPERTY(DefaultComponent, Attach = Sphere)
	UStaticMeshComponent DiscoBallHolder;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent GroundPoundFXLocation;

	UPROPERTY(DefaultComponent, Attach = Sphere)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent JumpOnAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent GroundpoundSingleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent GroundpoundDoubleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DestroyDiscoBallAudioEvent;
	
	UPROPERTY()
	FDiscoBallSignature StartDiscoBall;
	UPROPERTY()
	FDiscoBallSignature OnDestroyDiscoBall;

	UPROPERTY()
	TArray<UStaticMeshComponent> Shrapnelz;

	UPROPERTY()
	float YOffset = 0.f;

	UPROPERTY()
	float CodyOffset = 0.f;

	UPROPERTY()
	float MayOffset = 0.f;

	UPROPERTY()
	float CurrentDistanceAlongSplinerino = 0.f;

	UPROPERTY()
	float DefaultSpeedAlongSplinerino = 3200.f;

	UPROPERTY()
	float CurrentSpeedAlongSplinerino = 0.f;

	UPROPERTY()
	bool BallActive = true;

	UPROPERTY()
	FVector BallTravelDirection;

	UPROPERTY()
	ASplineActor SplineReference;

	UPROPERTY()
	bool TimeForJump = false;

	UPROPERTY()
	UStaticMesh DiscoBallHolder2;

	UPROPERTY()
	UStaticMesh DiscoBallHolder3;

	UPROPERTY()
	TSubclassOf<UHazeUserWidget> GroundPoundWidget;

	UPROPERTY()
	UNiagaraSystem GroundPoundFX;

	UPROPERTY()
	UFoghornVOBankDataAssetBase VOBank;


	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.LowerBound = 0.f;
	default PhysValue.UpperBound = 3500.f;
	default PhysValue.LowerBounciness = 0.5f;
	default PhysValue.UpperBounciness = 1.f;
	default PhysValue.Friction = 2.3f;
	
	bool MayHasRecentlyPounded;

	bool CodyHasRecentlyPounded;

	bool BothPlayersHasGroundPounded = false;

	bool CutSceneHasStarted = false;

	UPROPERTY()
	bool bUseSlopeAmount = true;

	FVector NewLoc;

	FVector CurrentLocation;
	
	FRotator CurrentRotation;

	FHazeAcceleratedFloat BallSideOffset;

	float SphereRadius = 0.f;

	float SpeedAddition = 1.f;

	float Drag = 0.5f;

	float MayTimer = 0.f;

	float CodyTimer = 0.f;

	float MaySinkAmount = 0.f;

	float CodySinkAmount = 0.f;

	float PlayerWeightSinkMax = -150.f;

	float MayGroundPoundAmount = 0.f;

	float CodyGroundPoundAmount = 0.f;

	FVector TargetPoundActorLocation;

	FVector NewPoundActorLocation;

	float StartingZLocation = 0.f;

	int DoubleGroundPoundAmount = 0;

	int AmountOfPlayersOnBall = 0;

	private bool bDestroyDiscoBall = false;
	private bool bIsDiscoBallDestroyed = false;

	bool IsDiscoBallDestroyed() const { return bIsDiscoBallDestroyed; }

	UPROPERTY()
	UCurveFloat AccelerationCurve;

	FTimerHandle RemoteWaitTimerHandle;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FVector DummyOrigin;
		FVector DummyBoxExtent;
		System::GetComponentBounds(UStaticMeshComponent::Get(this), DummyOrigin, DummyBoxExtent, SphereRadius);
		
		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"DiscoballJumpedOn");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);
		
		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"DiscoballJumpedOff");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
		

		//Bind groundpound event
		FActorGroundPoundedDelegate GroundPoundedz;
		GroundPoundedz.BindUFunction(this, n"WasGroundPounded");
		BindOnActorGroundPounded(this, GroundPoundedz);

		StartingZLocation = GetActorLocation().Z;

	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		System::ClearAndInvalidateTimerHandle(RemoteWaitTimerHandle);
	}

	UFUNCTION()
	void DiscoballJumpedOn(AHazePlayerCharacter Player, FHitResult Hit)
	{
		PhysValue.AddImpulse(300.f);
		AmountOfPlayersOnBall++;
		UHazeAkComponent::HazePostEventFireForget(JumpOnAudioEvent, this.GetActorTransform());

	}

	UFUNCTION()
	void DiscoballJumpedOff(AHazePlayerCharacter Player)
	{
		AmountOfPlayersOnBall--;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		if (!BallActive)
		{
			PhysValue.AddAcceleration(400 * AmountOfPlayersOnBall);
			PhysValue.SpringTowards(0.f, 75.f - 20 * DoubleGroundPoundAmount);
			PhysValue.Update(DeltaTime);
			Sphere.SetRelativeLocation(FVector::UpVector * -PhysValue.Value);
		}
	
		//Cody and may offset values get fed from Discoball.as
		float TargetOffset = (CodyOffset + MayOffset) / 2.f;
		float OffsetAmount = FMath::Abs(TargetOffset);
		float DeadZone = 50.f;

		if (OffsetAmount <= DeadZone)
		{
			BallSideOffset.Velocity -= BallSideOffset.Velocity * 5.f * DeltaTime;
			BallSideOffset.Value += BallSideOffset.Velocity * DeltaTime;
			BallSideOffset.Value = FMath::Clamp(BallSideOffset.Value, -1500.f, 1500.f);
		}

		else
			BallSideOffset.AccelerateTo(1500 * FMath::Sign(TargetOffset), 10000.f / (OffsetAmount - DeadZone), DeltaTime);

		
		YOffset = BallSideOffset.Value;

		//Movement
		//Calculate discoball movement forward along spline and offset depending on player locations

		CurrentLocation = SplineReference.Spline.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSplinerino, ESplineCoordinateSpace::World);
		CurrentRotation = SplineReference.Spline.GetRotationAtDistanceAlongSpline(CurrentDistanceAlongSplinerino, ESplineCoordinateSpace::World);
		
		FVector BallRightVector = CurrentRotation.GetRightVector();
		
		//Use this if you want ball to move sideways depending on players position on ball
		// FVector RightVectorOffsetAmount = BallRightVector * (YOffset * -1.f);
		// FVector NewLocation = CurrentLocation + RightVectorOffsetAmount + SphereRadius;

		FVector SplineUpVector = SplineReference.Spline.GetUpVectorAtDistanceAlongSpline(CurrentDistanceAlongSplinerino, ESplineCoordinateSpace::World);
		FVector NewLocation = CurrentLocation + (SplineUpVector * SphereRadius);


		//Increase / decrease speed of ball in slopes
		FVector ZDifference = CurrentLocation - SplineReference.Spline.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSplinerino + 100.f, ESplineCoordinateSpace::World);
		ZDifference = FVector(0.f, 0.f, ZDifference.Z);
		float SlopeAmount = ZDifference.Z;
	
		if (bUseSlopeAmount)
			SlopeAmount = FMath::GetMappedRangeValueClamped(FVector2D(-20.f, 40.f), FVector2D(-1.f, 1.f), SlopeAmount);
		else
			SlopeAmount = 0.f;
		
		
		
		// Print("SlopeAmount: "+SlopeAmount);
	
		SpeedAddition = SpeedAddition + (SlopeAmount * DeltaTime);
		
			if (!TimeForJump)
			{
				SpeedAddition = FMath::Clamp(SpeedAddition, 1.f, 1.4f);
				// Print("Not Time For Jump");
			}
			else
			{
				SpeedAddition = FMath::Clamp(SpeedAddition, 1.f, 2.f);
			// Print("OK It's Time For Jump");
			}

		// Print("Speed Addition"+SpeedAddition);
		

		CurrentSpeedAlongSplinerino = DefaultSpeedAlongSplinerino * SpeedAddition;
		HazeAkComp.SetRTPCValue("Rtpc_Nightclub_Platform_DiscoBall_SlopeAmount", SlopeAmount);
	

		//Rotation
		//Calculate camera rotation
		FRotator TargetCameraRotation = FRotator (GetActorRotation().Pitch, CurrentRotation.Yaw, GetActorRotation().Roll);
		FRotator CameraRotation = FMath::RInterpTo(CameraRoot.WorldRotation, TargetCameraRotation, DeltaTime, 0.7f);


		// Calculate travel direction
		BallTravelDirection = NewLocation - ActorLocation;
		BallTravelDirection = BallTravelDirection.GetSafeNormal();

		//Set the rotation of the sphere component
		FVector ActorCross = GetActorUpVector().CrossProduct(BallTravelDirection);
		FRotator BallDirectionRotation = FMath::RotatorFromAxisAndAngle(ActorCross, (CurrentSpeedAlongSplinerino / 60.f) * DeltaTime);
		FRotator FinalRotation = Sphere.GetWorldRotation().Compose(BallDirectionRotation);

		//Set ball rotations and position
		if (BallActive)
		{
			Sphere.SetWorldRotation(FinalRotation);
			SetActorLocation(NewLocation);
			CameraRoot.SetWorldRotation(CameraRotation);
			CurrentDistanceAlongSplinerino = CurrentDistanceAlongSplinerino + CurrentSpeedAlongSplinerino * DeltaTime;
		}
		
		
		if(!BallActive && !CutSceneHasStarted)
		{			
			// float GoingBackSpeed = 300.f;

			if(!BothPlayersHasGroundPounded)
			{
				// MaySinkAmount += GoingBackSpeed * DeltaTime;
				// MaySinkAmount = FMath::Clamp(MaySinkAmount, PlayerWeightSinkMax, 0.f);

				// CodySinkAmount += GoingBackSpeed * DeltaTime;
				// CodySinkAmount = FMath::Clamp(CodySinkAmount, PlayerWeightSinkMax, 0.f);
				
				MayTimer -= DeltaTime;
				MayHasRecentlyPounded = MayTimer >= 0.f;
						
				CodyTimer -= DeltaTime;
				CodyHasRecentlyPounded = CodyTimer >= 0.f;
			}

			// TargetPoundActorLocation = FVector(ActorLocation.X, ActorLocation.Y, StartingZLocation + CodySinkAmount + MaySinkAmount);
			// NewPoundActorLocation = FMath::VInterpTo(ActorLocation, TargetPoundActorLocation, DeltaTime, 20.f);
			// SetActorLocation(NewPoundActorLocation);

			if(MayHasRecentlyPounded && CodyHasRecentlyPounded)
			{	
				if(HasControl())
				{
					NetIncreaseDoubleGroundPoundAmount();
				}															
			}
			
		}
	}

	//Dev funtion to test end of discoball ride
	UFUNCTION(BlueprintCallable)
	void SmokePuff03()
	{
		FVector DebugLocation = SplineReference.Spline.GetLocationAtDistanceAlongSpline(SplineReference.Spline.SplineLength - 30000.f, ESplineCoordinateSpace::World);
		FRotator DebugRotation = SplineReference.Spline.GetRotationAtDistanceAlongSpline(SplineReference.Spline.SplineLength - 30000.f, ESplineCoordinateSpace::World);
		CurrentDistanceAlongSplinerino = SplineReference.Spline.SplineLength - 30000.f;
		SetActorLocation(DebugLocation);
		SetActorRotation(DebugRotation);
	}

	UFUNCTION(NetFunction)
	void NetIncreaseDoubleGroundPoundAmount()
	{
		CodyTimer = 0.f;
		MayTimer = 0.f;
		DoubleGroundPoundAmount += 1;
		PlayGroundPoundFX();

		if(DoubleGroundPoundAmount == 1)
		{
			DiscoBallHolder.SetStaticMesh(DiscoBallHolder2);
			UHazeAkComponent::HazePostEventFireForget(GroundpoundDoubleAudioEvent, this.GetActorTransform());
		}
			

		else if(DoubleGroundPoundAmount == 2)
		{
			DiscoBallHolder.SetStaticMesh(DiscoBallHolder3);
			UHazeAkComponent::HazePostEventFireForget(GroundpoundDoubleAudioEvent, this.GetActorTransform());
			PlayFoghornVOBankEvent(VOBank, n"FoghornDBMusicNightclubBeatSectionDiscoballPound");
		}
			
			

		if(DoubleGroundPoundAmount > 2)
		{
			CutSceneHasStarted = true;
			UHazeAkComponent::HazePostEventFireForget(GroundpoundDoubleAudioEvent, this.GetActorTransform());
			DiscoBallHolder.DestroyComponent(this);
			StartDiscoBall.Broadcast();
		}
	}

	UFUNCTION()
	void PlayGroundPoundFX()
	{
			Niagara::SpawnSystemAttached(GroundPoundFX, GroundPoundFXLocation, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
	}


	UFUNCTION()
	void WasGroundPounded(AHazePlayerCharacter Player)
	{
		PhysValue.AddImpulse(1200.f);

		if(!BothPlayersHasGroundPounded)
		{
			UHazeAkComponent::HazePostEventFireForget(GroundpoundSingleAudioEvent, this.GetActorTransform());
		}
		

		if (Player.IsMay() && !BothPlayersHasGroundPounded)
		{
			MayTimer = 2.f;
			MayGroundPoundAmount += 1.f;
			// MaySinkAmount = PlayerWeightSinkMax;
		}
		
			else if (Player.IsCody() && !BothPlayersHasGroundPounded)
			{
				CodyTimer = 2.f;
				CodyGroundPoundAmount += 1.f;
				// CodySinkAmount = PlayerWeightSinkMax;
			}

		if (Player.IsMay() && MayGroundPoundAmount - CodyGroundPoundAmount > 4)
		{
			PlayFoghornVOBankEvent(VOBank, n"FoghornDBMusicNightclubBeatSectionDiscoballHint");
		}

	}

	UFUNCTION(BlueprintCallable)
	void GameOverRestart()
	{
		CurrentDistanceAlongSplinerino = 0.f;
	}

	UFUNCTION()
	void DestroyDiscoball()
	{
		if(bIsDiscoBallDestroyed)
			return;

		if(HasControl())
		{
			NetDestroyDiscoBall();
		}
		else
		{
			Internal_DestroyDiscoBall();
		}
	}

	UFUNCTION(NetFunction)
	void NetDestroyDiscoBall()
	{
		
		if(!HasControl() && !bIsDiscoBallDestroyed)
		{
			RemoteWaitTimerHandle = System::SetTimer(this, n"Handle_RemoteDestroyDiscoBall", 2.0f, false);
		}
		else
		{
			Internal_DestroyDiscoBall();
		}
	}

	private void Internal_DestroyDiscoBall()
	{
		if (bIsDiscoBallDestroyed)
			return;
		bIsDiscoBallDestroyed = true;
		bDestroyDiscoBall = true;
		BP_OnDestroyDiscoBall();
		OnDestroyDiscoBall.Broadcast();
		System::ClearAndInvalidateTimerHandle(RemoteWaitTimerHandle);
		HazeAkComp.HazePostEvent(DestroyDiscoBallAudioEvent);
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Destroy Discoball"))
	void BP_OnDestroyDiscoBall() {}

	UFUNCTION()
	private void Handle_RemoteDestroyDiscoBall()
	{
		Internal_DestroyDiscoBall();
	}
}