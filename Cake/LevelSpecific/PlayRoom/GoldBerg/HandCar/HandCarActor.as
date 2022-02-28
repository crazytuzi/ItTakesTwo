// import Peanuts.Animation.Features.LocomotionFeatureToyCart;

// event void FChangeCameraInHandCart(AHazePlayerCharacter Player, bool InCart);
// event void FChangeFOVUp();
// event void FChangeFOVDown();
// event void FSetNewSpline(USplineComponent SplineComponent, bool StartAtEnd);
// event void FGoingUpASlope();
// event void FSlopeStopped();
// event void FFirstPlayerInteracted();

// UCLASS(Abstract)
// class AHandCarActor : AHazeActor
// {
// 	UPROPERTY(RootComponent, DefaultComponent)
// 	USceneComponent Root;

// 	UPROPERTY(DefaultComponent, Attach = Root)
// 	USceneComponent Base;

// 	UPROPERTY(DefaultComponent, Attach = Base)
// 	UHazeSkeletalMeshComponentBase ToyCart;

// 	UPROPERTY(DefaultComponent, Attach = Base)
// 	UStaticMeshComponent HandCarCart;

// 	UPROPERTY(DefaultComponent, Attach = Base)
// 	UHazeTriggerComponent LeftInteraction;

// 	UPROPERTY(DefaultComponent, Attach = Base)
// 	UHazeTriggerComponent RightInteraction;

// 	UPROPERTY(DefaultComponent, Attach = Base)
// 	UStaticMeshComponent LeftSpotAttachPoint;

// 	UPROPERTY(DefaultComponent, Attach = Base)
// 	UStaticMeshComponent RightSpotAttachPoint;

// 	UPROPERTY(DefaultComponent, Attach = Base)
// 	UStaticMeshComponent PumpRoot;

// 	UPROPERTY(DefaultComponent, Attach = PumpRoot)
// 	UStaticMeshComponent PumpLever;
// 	default PumpLever.RelativeRotation = FRotator(35, 0, 0);

// 	UPROPERTY(DefaultComponent, Attach = Base)
// 	UStaticMeshComponent LeftUIAttachPoint;

// 	UPROPERTY(DefaultComponent, Attach = Base)
// 	UStaticMeshComponent MiddleUIAttachPoint;

// 	UPROPERTY(DefaultComponent, Attach = Base)
// 	UStaticMeshComponent RightUIAttachPoint;


// 	UPROPERTY()
// 	USplineComponent Spline;

// 	bool HasTrackSpline;

// 	UPROPERTY()	
// 	AHazePlayerCharacter PlayerAtLeftHandle;
// 	UPROPERTY()	
// 	AHazePlayerCharacter PlayerAtRightHandle;    

// 	AHazePlayerCharacter PlayerWithFullscreen;

// 	AHazePlayerCharacter InterruptingPlayer;

// 	bool LeftHandleHasPlayer;
// 	bool RightHandleHasPlayer; 

// 	bool bHasBoundAnimationTrigger = false;	

// 	FHazePlaySlotAnimationParams ActiveSlotAnim;

// 	UAnimInstance AnimInstance;

// 	UPROPERTY()
// 	ULocomotionFeatureToyCart Feature;

// 	UPROPERTY()
// 	FChangeCameraInHandCart ShouldChangePlayerCamera;
// 	UPROPERTY()
// 	FChangeFOVUp ChangeFOVUp;
// 	UPROPERTY()
// 	FChangeFOVDown ChangeFOVDown;
// 	UPROPERTY()
// 	FSetNewSpline SetNewSplineEvent;

// 	UPROPERTY()
// 	FFirstPlayerInteracted FirstPlayerInteracted;

// 	UPROPERTY()
// 	FGoingUpASlope GoingUpASlope;
// 	UPROPERTY()
// 	FSlopeStopped SlopeStopped;

// 	float SlopeBoost = 0.0f;
// 	float MaxSlopeBoost = 0.5f;
	   
// 	float TotalDistanceWithOffset;
// 	float CurrentDistance;
// 	float StartDistanceWithOffset = 2.0f;	

// 	UPROPERTY()
// 	float Speed;

// 	float MinSpeed = -200;
// 	float MaxSpeed = 200;

// 	float Acceleration = 0.0f;
// 	float PumpForce = 0.0f;

// 	float Friction = -0.08f;
// 	FVector SplineDirection;
// 	FVector GravityVector = FVector(0, 0, -980.0f);
// 	FVector NormalizedGravityVector;	
// 	float GravityScale = 1.0f;
// 	float DotProduct;
// 	float MaxDotProd = 1.0f;
// 	float MinDotProd = -1.0f;

// 	float StartForceToAdd = 200.0f;
// 	float SlowForceToAdd = 400.0f;
// 	float MediumForceToAdd = 600.0f;
// 	float FastForceToAdd = 1500.0f;
// 	float InterruptionForceToAdd = -1000.0f;

// 	// bool HasFollower;

// 	bool bGoingDownSlope;

// 	float SlopeFriction = 0.0f;
// 	float MaxSlopeFriction = 0.005f;

// 	bool LeftPlayerHasPumped;
// 	bool RightPlayerHasPumped;

// 	bool PumpDoneMoving = true;

// 	FRotator DeltaRotation = FRotator(200, 0, 0);
// 	FRotator LeftUpRotation = FRotator(35, 0, 0);
// 	FRotator LeftDownRotation = FRotator(-35, 0, 0);

// 	UPROPERTY()
// 	bool InBossFight = false;

// 	UPROPERTY()
// 	bool MayStarted = false;

// 	UPROPERTY()
// 	bool CodyStarted = false;

// 	UPROPERTY()
// 	bool MayPumped = false;

// 	UPROPERTY()
// 	bool CodyPumped = false;

// 	UPROPERTY()
// 	bool Interrupted = false;

// 	bool bGoingUpSlope;
// 	bool bShowingSlopeWidget;

// 	float SlopeTimer;
// 	float SlopeDurationBeforeShowingWidget = 1.0f;

// 	float FastThreshold;

// 	float MediumThreshold;

// 	float SlowThreshold;

// 	float LengthMayPushSlow;
// 	float LengthMayPushMedium;
// 	float LengthMayPushFast;
// 	float LengthMayStart;

// 	float LengthCodyPushSlow;
// 	float LengthCodyPushMedium;
// 	float LengthCodyPushFast;
// 	float LengthCodyStart;	

// 	float LeverMovingTimer;
// 	float LeverMovingDuration;

// 	bool Stopped;

// 	UPROPERTY()
// 	EPumpSpeed CurrentPumpSpeed;

// 	UPROPERTY()
// 	EPumpPosition CurrentPumpPosition = EPumpPosition::Middle;

// 	bool PumpWindow = false;

// 	bool BothPlayersAreInHandCar = false;

// 	float WindowTimer;

// 	float InterruptedTimer;
// 	float InterruptedDuration = 1.0f;

// 	float InterruptFriction = 1.0f;
// 	float MaxInterruptFriction = 10.0f;


// 	UPROPERTY()
// 	TSubclassOf<UCameraShakeBase> InterruptionCameraShake;

// 	UPROPERTY()
// 	UForceFeedbackEffect InterruptionForceFeedback;

// 	UPROPERTY()
// 	UNiagaraSystem InterruptionEffect;

// 	UCameraShakeBase CurrentActiveShake = nullptr;

	
// 	UFUNCTION(BlueprintCallable)
// 	void BeginPlayInAS()
// 	{
// 		SetupTriggerComponent();
// 		NormalizedGravityVector = GravityVector;
// 		NormalizedGravityVector.Normalize();
// 		SetNewSplineEvent.AddUFunction(this, n"SetNewSpline");

// 		FastThreshold = Feature.FastThreshold;
// 		MediumThreshold = Feature.MediumThreshold;
// 		SlowThreshold = Feature.SlowThreshold;

// 		LengthMayPushSlow = Feature.Slow.Sequence.PlayLength;
// 		LengthMayPushMedium = Feature.Medium.Sequence.PlayLength;
// 		LengthMayPushFast = Feature.Fast.Sequence.PlayLength;
// 		LengthMayStart = Feature.Slow.Sequence.PlayLength;

// 		LengthCodyPushSlow = Feature.Slow.Sequence.PlayLength;
// 		LengthCodyPushMedium = Feature.Medium.Sequence.PlayLength;
// 		LengthCodyPushFast = Feature.Fast.Sequence.PlayLength;
// 		LengthCodyStart = Feature.Slow.Sequence.PlayLength;

// 		CurrentPumpSpeed = EPumpSpeed::SlowPump;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void Tick(float DeltaTime)
// 	{
// 		if(!InBossFight)
// 		{
// 			if(HasTrackSpline && !Stopped)
// 			{
// 				SplineDirection = Spline.GetDirectionAtDistanceAlongSpline(CurrentDistance, ESplineCoordinateSpace::World);
// 				DotProduct = SplineDirection.DotProduct(NormalizedGravityVector);
// 				DotProduct = FMath::Clamp(DotProduct, MinDotProd, MaxDotProd);
// 				float GravitySize = GravityVector.Size();
				
// 				Acceleration = (DotProduct+SlopeBoost-SlopeFriction * (GravitySize * GravityScale)) + (Speed * (Friction*InterruptFriction)) + PumpForce;

// 				Speed += (Acceleration * DeltaTime);

// 				Speed = FMath::Clamp(Speed, MinSpeed, MaxSpeed);

// 				if(Speed != 0)
// 				{
// 					CurrentDistance = CurrentDistance + (Speed);

// 					CurrentDistance = FMath::Clamp(CurrentDistance, StartDistanceWithOffset, TotalDistanceWithOffset-1);
					
// 					Root.SetWorldLocation(Spline.GetLocationAtDistanceAlongSpline(CurrentDistance, ESplineCoordinateSpace::World));
// 					Root.SetWorldRotation(Spline.GetRotationAtDistanceAlongSpline(CurrentDistance, ESplineCoordinateSpace::World));
// 				}
				
// 				if(Speed >= 100 && DotProduct > 0.5f && !bGoingDownSlope)
// 				{
// 					ChangeFOVUp.Broadcast();
// 					SlopeBoost = MaxSlopeBoost;
// 					bGoingDownSlope = true;
// 				}
// 				else if(bGoingDownSlope)
// 				{
// 					ChangeFOVDown.Broadcast();
// 					SlopeBoost = 0.0f;				
// 					bGoingDownSlope = false;
// 				}

// 				if(DotProduct < -0.20)
// 				{
// 					if(!bGoingUpSlope)
// 					{
// 						bGoingUpSlope = true;		
// 					}

// 					if(bGoingUpSlope && !bShowingSlopeWidget)
// 					{
// 						SlopeTimer += DeltaTime;
// 						if(SlopeTimer >= SlopeDurationBeforeShowingWidget)
// 						{
// 							GoingUpASlope.Broadcast();
// 							bShowingSlopeWidget = true;
// 							SlopeTimer = 0.0f;
// 							SlopeFriction = MaxSlopeFriction;						
// 						}			
// 					}
// 				}
// 				else
// 				{
// 					if(bGoingUpSlope)
// 					{
// 						SlopeStopped.Broadcast();
// 						SlopeTimer = 0.0f;
// 						bGoingUpSlope = false;
// 						bShowingSlopeWidget = false;
// 						SlopeFriction = 0;
// 					}
// 				}

// 				if(!PumpDoneMoving)
// 				{
// 					MoveLeverTimer(DeltaTime);
// 				}
// 				else
// 				{
// 					if(PumpWindow)
// 					{
// 						WindowTimer += DeltaTime;
// 						if(WindowTimer >= SlowThreshold)
// 						{
// 							PumpWindowIsOver();
// 						}
// 					}
// 				}

// 				if(Interrupted)
// 				{
// 					InterruptedTimer += DeltaTime;
// 					if(InterruptedTimer >= InterruptedDuration)
// 					{
// 						InterruptionFinished();
// 					}
// 				}

// 				ResetForces();
// 			}
// 		}
// 	}

// 	void DeclareMoveLeverValues()
// 	{
// 		if(CodyPumped)
// 		{
// 			switch(CurrentPumpSpeed)
// 			{
// 				case EPumpSpeed::FastPump:
// 					LeverMovingDuration = LengthCodyPushFast;
// 					break;
// 				case EPumpSpeed::MediumPump:
// 					LeverMovingDuration = LengthCodyPushMedium;
// 					break;
// 				case EPumpSpeed::SlowPump:
// 					LeverMovingDuration = LengthCodyPushSlow;
// 					break;
// 			}
// 		}
// 		else if(MayPumped)
// 		{
// 			switch(CurrentPumpSpeed)
// 			{
// 				case EPumpSpeed::FastPump:
// 					LeverMovingDuration = LengthMayPushFast;
// 					break;
// 				case EPumpSpeed::MediumPump:
// 					LeverMovingDuration = LengthMayPushMedium;
// 					break;
// 				case EPumpSpeed::SlowPump:
// 					LeverMovingDuration = LengthMayPushSlow;
// 					break;
// 			}
// 		}
// 		else if(CodyStarted)
// 		{
// 			LeverMovingDuration = LengthCodyStart;
// 		}
// 		else if(MayStarted)
// 		{
// 			LeverMovingDuration = LengthMayStart;			
// 		}
// 	}

// 	void MoveLeverTimer(float DeltaTime)
// 	{ 
// 		if(LeverMovingTimer >= LeverMovingDuration)
// 		{
// 			FinishPumping();
// 		}

// 		LeverMovingTimer += DeltaTime;
// 	}

// 	void InterrputedPump(AHazePlayerCharacter PlayerWhoInterrupted)
// 	{
// 		LeverMovingTimer = 0.0f;
// 		Interrupted = true;
// 		InterruptingPlayer = PlayerWhoInterrupted;

// 		ResetForces();

// 		CodyPumped = false;
// 		MayPumped = false;
// 		CodyStarted = false;
// 		MayStarted =  false;

// 		InterruptFriction = MaxInterruptFriction;

// 		Print("Interrupted!", 1.0f);

// 		if(PlayerAtLeftHandle != nullptr)
// 		{
// 			CurrentActiveShake = PlayerAtLeftHandle.PlayCameraShake(InterruptionCameraShake);
// 			PlayerAtLeftHandle.PlayForceFeedback(InterruptionForceFeedback, false, true, n"HandCarInterrupted");
// 		}

// 		if(PlayerAtRightHandle != nullptr)
// 		{
// 			CurrentActiveShake = PlayerAtRightHandle.PlayCameraShake(InterruptionCameraShake);
// 			PlayerAtRightHandle.PlayForceFeedback(InterruptionForceFeedback, false, true, n"HandCarInterrupted");
// 		}
// 	}

// 	void FinishPumping()
// 	{
// 		PumpDoneMoving = true;
// 		LeverMovingTimer = 0.0f;
// 		StartPumpWindow();
// 	}

// 	void PumpWindowIsOver()
// 	{
// 		PumpWindow = false;
// 		CurrentPumpPosition = EPumpPosition::Middle;
// 	}

// 	void StartPumpWindow()
// 	{
// 		PumpWindow = true;
// 		WindowTimer = 0.0f;
// 	}
	
// 	void Pump(AHazePlayerCharacter Player)
// 	{
// 		if(Stopped)
// 		{
// 			InterrputedPump(Player);
// 			return;
// 		}
		
// 		if(PumpDoneMoving && !Interrupted)
// 		{
// 			if(Player == PlayerAtRightHandle)
// 			{
// 				if(CurrentPumpPosition == EPumpPosition::LeftDown && PumpWindow)
// 				{
// 					PumpDoneMoving = false;

// 					PumpWindow = false;
// 					CheckPumpSpeed();
// 					DeclareMoveLeverValues();					

// 					if(CurrentPumpSpeed == EPumpSpeed::FastPump)
// 						PumpForce = FastForceToAdd;
// 					else if(CurrentPumpSpeed == EPumpSpeed::MediumPump)
// 						PumpForce = MediumForceToAdd;
// 					else
// 						PumpForce = SlowForceToAdd;

// 					if(Speed < 0)
// 					{
// 						Speed = 0;
// 					}

// 					if(PlayerAtRightHandle.IsCody())
// 					{
// 						CodyPumped = true;

// 						MayPumped = false;
// 						CodyStarted = false;
// 						MayStarted =  false;
// 					}
// 					else if(PlayerAtRightHandle.IsMay())
// 					{
// 						MayPumped = true;

// 						CodyPumped = false;
// 						CodyStarted = false;
// 						MayStarted =  false;
// 					}
// 					CurrentPumpPosition = EPumpPosition::RightDown;
// 				}

// 				else if(CurrentPumpPosition == EPumpPosition::Middle)
// 				{
// 					PumpDoneMoving = false;

// 					CheckPumpSpeed();
// 					DeclareMoveLeverValues();
// 					PumpForce = StartForceToAdd;

// 					if(Speed < 0)
// 					{
// 						Speed = 0;
// 					}							
										
// 					if(PlayerAtRightHandle.IsCody())
// 					{
// 						CodyStarted = true;

// 						CodyPumped = false;
// 						MayPumped = false;
// 						MayStarted =  false;
// 					}
// 					else if(PlayerAtRightHandle.IsMay())
// 					{
// 						MayStarted = true;
						
// 						CodyPumped = false;
// 						MayPumped = false;
// 						CodyStarted =  false;
// 					}
// 					CurrentPumpPosition = EPumpPosition::RightDown;
// 				}
// 				else
// 				{
// 					InterrputedPump(Player);
// 				}
// 			}
// 			else
// 			{
// 				if(CurrentPumpPosition == EPumpPosition::RightDown && PumpWindow)
// 				{
// 					PumpDoneMoving = false;

// 					PumpWindow = false;
// 					CheckPumpSpeed();
// 					DeclareMoveLeverValues();


// 					if(CurrentPumpSpeed == EPumpSpeed::FastPump)
// 						PumpForce = FastForceToAdd;
// 					else if(CurrentPumpSpeed == EPumpSpeed::MediumPump)
// 						PumpForce = MediumForceToAdd;
// 					else
// 						PumpForce = SlowForceToAdd;


// 					if(Speed < 0)
// 					{
// 						Speed = 0;
// 					}				
			
// 					if(PlayerAtLeftHandle.IsCody())
// 					{
// 						CodyPumped = true;

// 						MayPumped = false;
// 						CodyStarted = false;
// 						MayStarted =  false;
// 					}
// 					else if(PlayerAtLeftHandle.IsMay())
// 					{
// 						MayPumped = true;

// 						CodyPumped = false;
// 						CodyStarted = false;
// 						MayStarted =  false;
// 					}

// 					CurrentPumpPosition = EPumpPosition::LeftDown;
// 				}

// 				else if(CurrentPumpPosition == EPumpPosition::Middle)
// 				{
// 					PumpDoneMoving = false;
					
// 					CheckPumpSpeed();
// 					DeclareMoveLeverValues();
// 					PumpForce = StartForceToAdd;

// 					if(Speed < 0)
// 					{
// 						Speed = 0;
// 					}			
										
// 					if(PlayerAtLeftHandle.IsCody())
// 					{
// 						CodyStarted = true;

// 						CodyPumped = false;
// 						MayPumped = false;
// 						MayStarted =  false;
// 					}
// 					else if(PlayerAtLeftHandle.IsMay())
// 					{
// 						MayStarted = true;

// 						CodyPumped = false;
// 						MayPumped = false;
// 						CodyStarted =  false;
// 					}

// 					CurrentPumpPosition = EPumpPosition::LeftDown;
// 				}
// 				else
// 				{
// 					InterrputedPump(Player);
// 				}
// 			}	
// 		}
// 		else
// 		{
// 			if(!PumpWindow)
// 				InterrputedPump(Player);
// 		}
// 	}

// 	void InterruptionFinished()
// 	{
// 		Interrupted = false;
// 		InterruptingPlayer = nullptr;
// 		InterruptedTimer = 0.0f;
// 		CurrentPumpPosition = EPumpPosition::Middle;
// 		PumpDoneMoving = true;

// 		InterruptFriction = 1.0f;
// 	}

// 	void CheckPumpSpeed()
// 	{
// 		if(CodyStarted || MayStarted)
// 			CurrentPumpSpeed = EPumpSpeed::SlowPump;
// 		else
// 		{
// 			if(WindowTimer <= FastThreshold)
// 			{
// 				if(CurrentPumpSpeed == EPumpSpeed::SlowPump)
// 					CurrentPumpSpeed = EPumpSpeed::MediumPump;
// 				else
// 					CurrentPumpSpeed = EPumpSpeed::FastPump;
// 			}

// 			if(WindowTimer <= MediumThreshold)
// 			{
// 				CurrentPumpSpeed = EPumpSpeed::MediumPump;
// 			}

// 			if(WindowTimer <= SlowThreshold)
// 			{
// 				CurrentPumpSpeed = EPumpSpeed::SlowPump;
// 			}
// 		}
// 	}

// 	void ResetForces()
// 	{
// 		PumpForce = 0.0f;
// 	}

// 	void SetupTriggerComponent()
// 	{
// 		FHazeShapeSettings ActionShape;
// 		ActionShape.BoxExtends = FVector(100.f, 100.f, 100.f);
// 		ActionShape.Type = EHazeShapeType::Box;

// 		FTransform ActionTransform;
// 		ActionTransform.SetScale3D(FVector(1.f));

// 		FHazeDestinationSettings MovementSettings;
// 		//MovementSettings.MovementMethod = EHazeMovementMethod::Disabled;

// 		FHazeActivationSettings ActivationSettings;
// 		ActivationSettings.ActivationType = EHazeActivationType::Action;
		

// 		FHazeTriggerVisualSettings VisualSettings;
// 		VisualSettings.VisualOffset.Location = FVector(100.f, 0.f, 100.f);

// 		LeftInteraction.AddActionShape(ActionShape, ActionTransform);
// 		LeftInteraction.AddMovementSettings(MovementSettings);
// 		LeftInteraction.AddActivationSettings(ActivationSettings);
// 		LeftInteraction.SetVisualSettings(VisualSettings);

// 		RightInteraction.AddActionShape(ActionShape, ActionTransform);
// 		RightInteraction.AddMovementSettings(MovementSettings);
// 		RightInteraction.AddActivationSettings(ActivationSettings);
// 		RightInteraction.SetVisualSettings(VisualSettings);

// 		FHazeTriggerActivationDelegate LeftInteractionDelegate;
// 		LeftInteractionDelegate.BindUFunction(this, n"LeftInteractionActivated");
// 		LeftInteraction.AddActivationDelegate(LeftInteractionDelegate);

// 		FHazeTriggerActivationDelegate RightInteractionDelegate;
// 		RightInteractionDelegate.BindUFunction(this, n"RightInteractionActivated");
// 		RightInteraction.AddActivationDelegate(RightInteractionDelegate);
// 	}

// 	UFUNCTION(NotBlueprintCallable)
// 	void LeftInteractionActivated(UHazeTriggerComponent Component, AHazePlayerCharacter Player)
// 	{
// 		Player.SmoothSetLocationAndRotation(Component.WorldLocation, Component.WorldRotation);

// 		Player.SetCapabilityAttributeObject(n"HandCar", this);
// 		Player.SetCapabilityAttributeObject(n"Interaction", Component);
// 		Player.SetCapabilityActionState(n"UsingHandCar", EHazeActionState::Active);
// 		Component.Disable(n"Interacted");
		
// 		LeftHandleHasPlayer = true;
// 		PlayerAtLeftHandle = Player;
// 		ShouldChangePlayerCamera.Broadcast(Player, true);

// 		if(RightHandleHasPlayer && LeftHandleHasPlayer)
// 		{
// 			Player.SetViewSize(EHazeViewPointSize::Fullscreen);
// 			PlayerWithFullscreen = Player;
// 			BothPlayersAreInHandCar = true;			
// 		}
// 		else
// 		{
// 			FirstPlayerInteracted.Broadcast();
// 		}
// 	}

// 	UFUNCTION(NotBlueprintCallable)
// 	void RightInteractionActivated(UHazeTriggerComponent Component, AHazePlayerCharacter Player)
// 	{
// 		Player.SmoothSetLocationAndRotation(Component.WorldLocation, Component.WorldRotation);

// 		Player.SetCapabilityAttributeObject(n"HandCar", this);
// 		Player.SetCapabilityAttributeObject(n"Interaction", Component);
// 		Player.SetCapabilityActionState(n"UsingHandCar", EHazeActionState::Active);
// 		Component.Disable(n"Interacted");
		
// 		RightHandleHasPlayer = true;
// 		PlayerAtRightHandle = Player;

// 		ShouldChangePlayerCamera.Broadcast(Player, true);

// 		if(RightHandleHasPlayer && LeftHandleHasPlayer)
// 		{
// 			Player.SetViewSize(EHazeViewPointSize::Fullscreen);
// 			PlayerWithFullscreen = Player;
// 			BothPlayersAreInHandCar = true;
// 		}
// 		else
// 		{
// 			FirstPlayerInteracted.Broadcast();
// 		}
// 	}

// 	void ReleaseHandCar(UHazeTriggerComponent Interaction, AHazePlayerCharacter Player)
// 	{
// 		Interaction.Enable(n"Interacted");
// 		if(Player == PlayerAtLeftHandle)
// 		{
// 			LeftHandleHasPlayer = false;
// 			PlayerAtLeftHandle = nullptr;
						
// 		}
// 		else
// 		{
// 			RightHandleHasPlayer = false;
// 			PlayerAtRightHandle = nullptr;			
// 		}

// 		ShouldChangePlayerCamera.Broadcast(Player, false);

// 		Game::GetMay().SetViewSize(EHazeViewPointSize::Normal);
// 		Game::GetCody().SetViewSize(EHazeViewPointSize::Normal);

// 		BothPlayersAreInHandCar = false;
// 		PlayerWithFullscreen = nullptr;	
// 	}

// 	void SetPumpInputForPlayer(bool IsActioned, AHazePlayerCharacter Player)
// 	{
// 		if(Player == PlayerAtRightHandle)
// 		{
// 			if(IsActioned)
// 			{
// 				if(!RightPlayerHasPumped)
// 				{
// 					RightPlayerHasPumped = true;
// 					Pump(PlayerAtRightHandle);
// 				}
// 			}
// 			else
// 			{
// 				if(RightPlayerHasPumped)
// 				{
// 					RightPlayerHasPumped = false;

// 					if(PlayerAtRightHandle.IsMay())
// 					{
// 						MayPumped = false;
// 						MayStarted = false;
// 					}
// 					else
// 					{
// 						CodyPumped = false;
// 						CodyStarted = false;
// 					}
// 				}
// 			}

// 		}
// 		else
// 		{
// 			if(IsActioned)
// 			{
// 				if(!LeftPlayerHasPumped)
// 				{
// 					LeftPlayerHasPumped = true;
// 					Pump(PlayerAtLeftHandle);					
// 				}
// 			}
// 			else
// 			{
// 				if(LeftPlayerHasPumped)
// 				{
// 					LeftPlayerHasPumped = false;

// 					if(PlayerAtLeftHandle.IsMay())
// 					{
// 						MayPumped = false;
// 						MayStarted = false;						
// 					}
// 					else
// 					{
// 						CodyPumped = false;
// 						CodyStarted = false;						
// 					}
// 				}
// 			}

// 		}
// 	}

// 	UFUNCTION()
// 	void SetNewSpline(USplineComponent SplineComponent, bool StartAtEnd)
// 	{   
// 		HasTrackSpline = false;
// 		SetSpline(SplineComponent, StartAtEnd);
// 		Stopped = false;
// 	}

// 	UFUNCTION(BlueprintCallable)
// 	void StopCart()
// 	{   
// 		Speed = 0.0f;
// 		Stopped = true;
// 	}

// 	UFUNCTION()
// 	void SetSpline(USplineComponent SplineComponent, bool StartAtEnd)
// 	{
// 		Spline = SplineComponent;
// 		TotalDistanceWithOffset = Spline.SplineLength + 2;
		
// 		if(StartAtEnd)
// 		{
// 			CurrentDistance = TotalDistanceWithOffset;
// 			Root.SetWorldLocation(Spline.GetLocationAtDistanceAlongSpline(CurrentDistance, ESplineCoordinateSpace::World));
// 			Root.SetWorldRotation(Spline.GetRotationAtDistanceAlongSpline(CurrentDistance, ESplineCoordinateSpace::World));  
// 		}
// 		else
// 		{
// 			CurrentDistance = StartDistanceWithOffset;
// 			Root.SetWorldLocation(Spline.GetLocationAtDistanceAlongSpline(CurrentDistance, ESplineCoordinateSpace::World));
// 			Root.SetWorldRotation(Spline.GetRotationAtDistanceAlongSpline(CurrentDistance, ESplineCoordinateSpace::World));  
// 		}

// 		HasTrackSpline = true;
// 		Stopped = false;		
// 	}

// 	// void CartHasFollowed()
//     // {
//     //     HasFollower = true;
//     // }

// 	bool CheckIfIsPlayerAtRightHandle(AHazePlayerCharacter Player)
// 	{
// 		if(Player == PlayerAtRightHandle)
// 			return true;
// 		else
// 			return false; //player is at left handle
// 	}

// }

// enum EPumpSpeed
// {
//     FastPump,
// 	MediumPump,
// 	SlowPump
// }

// enum EPumpPosition
// {
//     LeftDown,
// 	Middle,
// 	RightDown
// }