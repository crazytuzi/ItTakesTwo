
// import Cake.Weapons.Match.MatchWeaponActor;
// import Cake.Weapons.Match.MatchWielderComponent;
// import Cake.Weapons.Match.MatchWeaponStatics;
// import Vino.Movement.Components.MovementComponent;
// import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
// import Vino.Movement.Helpers.BurstForceStatics;
// import Peanuts.Aiming.AutoAimStatics;

// /**
// 	This hook/grapple shot is a mix between 2 grapples. 

//  1. The Overwatch/JustCause grapple. It will lerp
// 	the player linearly to the destination
// 	and attach the player to that point.

//  2. The Fortnite grapple: Will apply an impulse 
// 	to get the player flying. 
// */

// enum EHookShotState
// {
// 	Idle,
// 	ShootingHook,
// 	HookAttached,	
// 	Flying,
// 	LandingStarted,
// 	Landed,
// 	ExitImpulseTriggered,
// 	Canceled
// };

// UCLASS(abstract)
// class UMatchWeaponHookShotCapability : UCharacterMovementCapability
// {
// 	default CapabilityTags.Add(n"Weapon");
// 	default CapabilityTags.Add(n"Movement");
// 	default CapabilityTags.Add(n"WeaponMatch");
// 	default CapabilityTags.Add(n"HookShot");
// 	default CapabilityTags.Add(CapabilityTags::MovementAction);
// 	default CapabilityTags.Add(CapabilityTags::GameplayAction);

// 	default TickGroup = ECapabilityTickGroups::ActionMovement;
// 	default TickGroupOrder = 1;

// 	// Will only activate this capability when aiming
// 	bool bOnlyEnabledWhenAiming = true;

// 	// How often we are allowed to shoot consecutive successful hookshots, 
// 	// -1 means disabled. @TODO: this should be based on different exit Animations,
// 	// which are chosen based on EstimatedTimeOfArrival. 
// 	float CustomHookShotCooldown = -1.5f;

// 	// Controls how far we are allowed to hook shot.
// 	float HookshotMaxDistance = 5000.f;

// 	// How many seconds until the final impulse (fortnite)
// 	// should kick in once we begin flight.
// 	float AutoExitImpulseTime = 0.2f;

// 	// Strength of the fornite impulse 
// 	float ExitImpulseMagnitude = 4500.f;

// 	// How much of the 'WorldUp' vector that should 
// 	// be used when creating the fortnite impulse vector
// 	float ExitImpulseRatio_UP = 4.f;

// 	// How much of the 'Camera looking direction' vector 
// 	// that should be used when creating the fortnite impulse vector
// 	float ExitImpulseRatio_HOOKDIR = 8.f;
	
// 	// The impulse speed of the 'Overwatch' hookshot. 
// 	float Flight_InitialSpeed = 4000.f;

// 	// The acceleration used while using the 'Overwatch' hookshot. 
// 	float Flight_InitialAcceleration = 2000.0f;

// 	//////////////////////////////////////////////////////////////////////////
// 	// Will auto add additional Speed/acceleration in order to 
// 	// to make sure that we reach the target on the desired time. 
// 	// 
// 	// Useful tool to calculate additional Speed/Acceleration
// 	// needed to reach target on the desired time. The capability
// 	// will print additional Speed/acceleration needed in order to
// 	// reach the target.
// 	//  
// 	// (-1 means to ignore MaxLerpTime in calculations) 
// 	float DEBUG_MaxFlightTime = 1.5f;					
// 	//////////////////////////////////////////////////////////////////////////

// //	// Strength of the slide impulse which will be pushed when playing the Slide_exit animation.
// //	float ExitSlideImpulse = 0.f;

// 	// Settings 
// 	//////////////////////////////////////////////////////////////////////////
// 	// Transients 

// 	AHazePlayerCharacter Player = nullptr;
// 	UMatchWielderComponent	WielderComp = nullptr;
// 	UHazeActiveCameraUserComponent CameraUser = nullptr;

// 	EHookShotState CurrentState = EHookShotState::Idle;

// 	float TimeUntilAutoFortniteImpulse = 0.f;
// 	float TotalEstimatedTravelTime = 0.f;
// 	float HookSplineLength = 0.f;

// 	float CurrentLerpTime = 0.f;
// 	float CurrentLerpFraction = 0.f;
// 	float CurrentSpeed = 0.f;
// 	float CurrentAcceleration = 0.f;

// 	float CurrentHookShotCooldownTimer = 0.f;

// 	FTransform InitTransform = FTransform::Identity;
// 	FRotator InitAimRotation = FRotator::ZeroRotator;		

// 	FVector HookImpactPoint_LOCAL = FVector::ZeroVector;
// 	FHitResult HookTargetHitData;

// 	FVector TraceDirection = FVector::ZeroVector;

// 	FTimerHandle ExitFlightTimer;

// 	// @TODO: do a proper fix once u have time.
// 	bool bHasBlockedMovement = false;		

// 	void ResetTransientData() 
// 	{
// 		bHasBlockedMovement = false;
// 		CurrentState = EHookShotState::Idle;
// 		HookTargetHitData.Reset();
// 		HookImpactPoint_LOCAL = FVector::ZeroVector;
// 		InitTransform = FTransform::Identity;
// 		InitAimRotation = FRotator::ZeroRotator;
// 		TraceDirection = FVector::ZeroVector;
// 		TimeUntilAutoFortniteImpulse = 0.f;
// 		HookSplineLength = 0.f;
// 		CurrentLerpTime = 0.f;
// 		CurrentSpeed = 0.f;
// 		CurrentLerpFraction = 0.f;
// 		CurrentAcceleration = 0.f;
// 		CurrentHookShotCooldownTimer = 0.f;
// 		TotalEstimatedTravelTime = 0.f;
// 	}

// 	// Transients 
// 	//////////////////////////////////////////////////////////////////////////
// 	// Capability Functions

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Super::Setup(SetupParams);
// 		Player = Cast<AHazePlayerCharacter>(Owner);
// 		WielderComp = UMatchWielderComponent::Get(Owner);
// 		CameraUser = UHazeActiveCameraUserComponent::Get(Owner);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if(WielderComp.GetMatchWeapon() == nullptr)
// 			return EHazeNetworkActivation::DontActivate;

// 		if (GetHookComponent().CurrentState != EHookCableState::Passive)
// 			return EHazeNetworkActivation::DontActivate;

// 		if(!MoveComp.CanCalculateMovement())
// 			return EHazeNetworkActivation::DontActivate;

// 		if(bOnlyEnabledWhenAiming && !IsActioning(ActionNames::WeaponAim))
// 			return EHazeNetworkActivation::DontActivate;

// 		if (!WasActionStarted(ActionNames::TEMPRightShoulder))
// 			return EHazeNetworkActivation::DontActivate;

// 		return EHazeNetworkActivation::ActivateFromControl;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if(WielderComp.GetMatchWeapon() == nullptr)
// 			return EHazeNetworkDeactivation::DeactivateLocal;

// 		if(CurrentState == EHookShotState::Canceled)
// 			return EHazeNetworkDeactivation::DeactivateFromControl;

// 		if(!MoveComp.CanCalculateMovement() && CurrentState != EHookShotState::ExitImpulseTriggered)
// 			return EHazeNetworkDeactivation::DeactivateLocal;

// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
// 	{
// 		OutParams.EnableTransformSynchronizationWithTime();
// 		NetInitData(Player.GetActorTransform(), Player.GetPlayerViewRotation());
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		// Move replica to the correct position
// 		if (!HasControl()) 
// 		{
//  			CameraUser.SnapCamera(InitAimRotation.Vector());
// 		}

// 		CurrentState = EHookShotState::ShootingHook;
// 		Owner.TriggerMovementTransition(this);
// 		FHitResult TraceData;
// 		DoHookTrace(TraceData);
// 		TraceDirection = (TraceData.TraceEnd - TraceData.TraceStart).GetSafeNormal();
// 		GetHookComponent().OnTargetReached.AddUFunction(this, n"HandleHookReachedDestination");
// 		GetHookComponent().ShootHook(TraceData);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams) 
// 	{
// 		GetHookComponent().OnTargetReached.UnbindObject(this);

// 		ClearAllCameraSettings();

// 		if (bHasBlockedMovement)
// 		{
// 			SetMutuallyExclusive(CapabilityTags::Movement, false);
// 			Player.UnblockCapabilities(CapabilityTags::Collision, this);
// 			bHasBlockedMovement = false;
// 		}

// 		ResetTransientData();

// 		System::ClearAndInvalidateTimerHandle(ExitFlightTimer);
// 		Player.ChangeActorWorldUp(FVector::UpVector);
// 		//Player.MeshOffsetComponent.OffsetRotationWithTime(Player.GetActorTransform().GetRotation());

// 		if (IsAnySlideAnimationPlaying())
// 		{
// 			PlayAnimation_Slide_Exit();
// //			const FVector SlideImpulse = Player.GetVelocity().GetSafeNormal() * ExitSlideImpulse;
// //			MoveComp.AddImpulse(SlideImpulse);
// 		}

// 		StopAllLoopingAnimations();
// 		GetHookComponent().BeginRetraction();
// 		GetHookComponent().CompleteRetraction();
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if (CurrentState == EHookShotState::Idle)
// 			return;

// 		if (CurrentState == EHookShotState::ShootingHook)
// 			return;

// 		if (CurrentState == EHookShotState::ExitImpulseTriggered)
// 		{
// 			CurrentHookShotCooldownTimer -= DeltaTime;
// 			if (CurrentHookShotCooldownTimer <= 0.f)
// 			{
// 				CurrentState = EHookShotState::Canceled;
// 			}
// 			return;
// 		}

// 		// Cancel into fortnite or Airmovement if we happen to jump 
// 		if (WasActionStarted(ActionNames::MovementJump))
// 		{
// 			if (CurrentState != EHookShotState::Landed)
// 				DoExitImpulse();
// 			else 
// 				CurrentState = EHookShotState::Canceled;
// 			return;
// 		}

// 		// auto cancel into fortnite or Airmovement based on timer
// 		if (CurrentState == EHookShotState::Flying)
// 		{
// 			if (AutoExitImpulseTime > 0.f)
// 			{
// 				TimeUntilAutoFortniteImpulse += DeltaTime;
// // 				if (!IsActioning(ActionNames::TEMPRightShoulder))
// // 				{
// 					if (TimeUntilAutoFortniteImpulse >= AutoExitImpulseTime)
// 					{
// 						if (CurrentState != EHookShotState::Landed)
// 							DoExitImpulse();
// 						else 
// 							CurrentState = EHookShotState::Canceled;
// 						return;
// 					}
// // 				}
// 			}
// 		}

// 		// Not really needed anymore. @TODO: remove this
// 		// and test it properly when we have time.
// 		if(!HookTargetHitData.bBlockingHit)
// 			return;

// 		UpdateFlight(DeltaTime);
// 	}

// 	// Capability func 
// 	//////////////////////////////////////////////////////////////////////////
// 	// Gameplay func 

// 	void DoExitImpulse() 
// 	{
// 		const FVector Dir_UP = FVector::UpVector * ExitImpulseRatio_UP;
//  		const FVector Dir_HOOK = TraceDirection * ExitImpulseRatio_HOOKDIR;
// 		const FVector Dir_HOOK_Tangential = Dir_HOOK.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
// 		const FVector Dir_CAM = Player.GetViewRotation().Vector();
// 		const FVector Dir_CAM_Tangential = Dir_CAM.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
// 		const FVector Dir_IMPULSE = (Dir_HOOK + Dir_UP).GetSafeNormal();

// 		//////////////////////////////////////////////////////////////////////////
// 		// We want to reduce the impulse if we are pointing downwards
// 		float ScaleByLookingDown = Dir_CAM.DotProduct(-FVector::UpVector);
// 		if (ScaleByLookingDown <= 0.f)
// 			ScaleByLookingDown = 1.f;
// 		else
// 			ScaleByLookingDown = 1.f - FMath::Pow(ScaleByLookingDown, 1.f);

// 		//////////////////////////////////////////////////////////////////////////
// 		// Scale the impulse in looking direction. This will make
// 		// sure that we don't apply the fortnite impulse if player 
// 		// isn't looking in the direction that the fortnite will be applied in.
// 		const float ScaleByLookingInHookDirection = FMath::Pow(FMath::Max(Dir_HOOK_Tangential.DotProduct(Dir_CAM_Tangential), 0.f), 0.45f);

// 		FVector Impulse = Dir_IMPULSE;
// 		Impulse *= ExitImpulseMagnitude;
// 		Impulse *= ScaleByLookingInHookDirection;
//  		Impulse *= ScaleByLookingDown;

// // 		Print("ScaleByLookingInHookDirection: " + ScaleByLookingInHookDirection, Duration = 8.f);
// // 		Print("ScaleByLookingDown: " + ScaleByLookingDown, Duration = 8.f);

// //		FVector From = Player.GetActorLocation();
// //    		System::DrawDebugLine(From, From + Dir_HOOK_Tangential * 1000.f, FLinearColor::Blue, 4.0f, 4.f);
// //   		System::DrawDebugLine(From, From + Dir_UP * 1000.f, FLinearColor::Green, 4.0f, 4.f);
// //   		System::DrawDebugLine(From, From + Impulse * 1000.f, FLinearColor::Red, 4.0f, 4.f);

// 		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"Fortnite Hookshot");
//   		MoveData.ApplyVelocity(Impulse);
// 		MoveComp.Move(MoveData);

// 		ApplyCameraSettings_Fortnite();

// 		CurrentState = EHookShotState::ExitImpulseTriggered;

// 		// Update cooldown timer
// 		const float TimeUntilArrival = FMath::Max(TotalEstimatedTravelTime - CurrentLerpTime, 0.f);
// 		if (CustomHookShotCooldown >= 0.f)
// 			CurrentHookShotCooldownTimer = CustomHookShotCooldown;
// 		else 
// 			CurrentHookShotCooldownTimer = TimeUntilArrival;

// 		// Play fortnite animation we have time
// // 		if (PlayerAnimParams_Fortnite_Enter.Animation != nullptr)
// // 		{
// // 			if (PlayerAnimParams_Fortnite_Enter.Animation.SequenceLength < TimeUntilArrival)
//  				PlayAnimation_Fortnite_Enter();
// // 		}

// 		// @TODO: quick workaround. Need to do this elsewhere 
// 		if (bHasBlockedMovement)
// 		{
// 			SetMutuallyExclusive(CapabilityTags::Movement, false);
// 			Player.UnblockCapabilities(CapabilityTags::Collision, this);
// 			bHasBlockedMovement = false;
// 		}

// // 		CurrentState = EHookShotState::Canceled;
// // 		Print("DoingFornite", Duration = 5.f);

// 	}

// 	UFUNCTION()
// 	void HandleHookReachedDestination(const FHitResult HitData)
// 	{
// 		if (IsBlocked() || !IsActive())
// 		{
// 			CurrentState = EHookShotState::Canceled;
// 			return;
// 		}

// 		// Cancel if the hook didn't hit anything.
// 		if (!HitData.bBlockingHit)
// 		{
// 			CurrentState = EHookShotState::Canceled;
// 			return;
// 		}

// 		CurrentState = EHookShotState::HookAttached;
// 		HookTargetHitData = HitData;

//    		SetMutuallyExclusive(CapabilityTags::Movement, true);
// 		Player.BlockCapabilities(CapabilityTags::Collision, this);
// 		bHasBlockedMovement = true;

// 		CalculateFlightImpulse();		
// 		BeginAnimationSequence();
// 		CurrentState = EHookShotState::Flying;
// 	}

// 	void CalculateFlightImpulse()
// 	{
// 		const FTransform ImpactTargetTransform = HookTargetHitData.GetComponent().GetWorldTransform();
// 		HookImpactPoint_LOCAL = ImpactTargetTransform.InverseTransformPosition(HookTargetHitData.ImpactPoint);

// 		HookSplineLength = (HookTargetHitData.ImpactPoint - InitTransform.GetLocation()).Size();

// 		CurrentSpeed = Flight_InitialSpeed;
// 		CurrentAcceleration = Flight_InitialAcceleration;

// 		// modify speed/acceleration to ensure that 
// 		// we reach the target on the desired time. 
// 		if (DEBUG_MaxFlightTime > 0.f)
// 		{
// 			const float DistMovedFromSpeed = Flight_InitialSpeed * DEBUG_MaxFlightTime;
// 			const float DistMovedFromAcceleration = 0.5f * DEBUG_MaxFlightTime * DEBUG_MaxFlightTime * Flight_InitialAcceleration;
// 			const float DistMovedOverMaxLerpTime = DistMovedFromSpeed + DistMovedFromAcceleration;
// 			if (DistMovedOverMaxLerpTime < HookSplineLength) 
// 			{
// 				const float DeltaDistanceNeeded = HookSplineLength - DistMovedOverMaxLerpTime;

// 				const float ExtraAcceleration = (DeltaDistanceNeeded / (DEBUG_MaxFlightTime * DEBUG_MaxFlightTime * 0.5f));
// 				CurrentAcceleration += ExtraAcceleration;
// 				Print("More Acceleration Needed: " + ExtraAcceleration, Duration = 5.f);

// // 				const float ExtraSpeed = (DeltaDistanceNeeded / MaxLerpTime);
// // 				CurrentSpeed += ExtraSpeed;
// // 				Print("More Speed Needed: " + ExtraSpeed, Duration = 5.f);
// 			}
// 		}

// 		// Predict time of arrival.
// 		const float A = HookSplineLength;
// 		const float B = CurrentSpeed;
// 		const float C = CurrentAcceleration * 0.5f; 
// 		if (C == 0.f && B != 0.f)
// 		{
// 			TotalEstimatedTravelTime = A / B;
// 		}
// 		else if (C != 0.f)
// 		{
//  			const float TheSqrt = FMath::Sqrt((4.f*A*C) + (B*B));
// 			const float R1 = (TheSqrt - B) / (2.f*C);
// 			const float R2 = (-(TheSqrt + B)) / (2.f*C);
// 			TotalEstimatedTravelTime = R1 > 0.f ? R1 : R2;
// // 			Print("ETA (R1): " + R1, 5.f, FLinearColor::White);
// // 			Print("ETA (R2): " + R2, 5.f, FLinearColor::White);
// 		}
// 		else 
// 		{
// 			TotalEstimatedTravelTime = 0.f;
// 		}
// // 		Print("ETA: " + EstimatedTravelTime, 5.f, FLinearColor::White);
// 	}

// 	void UpdateFlight(const float DeltaTime) 
// 	{
// 		CurrentLerpTime += DeltaTime;

// 		const FVector TargetLoc = GetTargetLocation();
// 		const FVector CurrentLoc = Player.GetActorLocation();
// 		const FVector ToTarget = TargetLoc - CurrentLoc;
// 		float DistanceToTarget = (TargetLoc - CurrentLoc).Size();

// 		const float DeltaMoveFromSpeed = CurrentSpeed * DeltaTime;
// 		const float DeltaMoveFromAcceleration = 0.5f * DeltaTime * DeltaTime * CurrentAcceleration;
// 		const float DeltaMove = DeltaMoveFromSpeed + DeltaMoveFromAcceleration;
// 		DistanceToTarget -= DeltaMove;

// 		if (CurrentLerpFraction == 1.f)
// 		{
// 			CurrentSpeed = 0.f;
// 			CurrentAcceleration = 0.f;
// 		}
// 		else 
// 		{
// 			CurrentSpeed += CurrentAcceleration * DeltaTime;
// 		}

// 		CurrentLerpFraction = 1.f - FMath::Max((DistanceToTarget / HookSplineLength), 0.f);
//  		CurrentLerpFraction = FMath::Clamp(CurrentLerpFraction, 0.f, 1.f);

// // 		Print("DeltaMove: " + DeltaMove, Color = FLinearColor::Yellow);
// // 		Print("CurrentLerpTime: " + CurrentLerpTime, Color = FLinearColor::Yellow);
// // 		Print("CurrentLerpSpeed: " + CurrentSpeed, Color = FLinearColor::Yellow);
// // 		Print("CurrentLerpAcceleration: " + CurrentAcceleration, Color = FLinearColor::Yellow);
// // 		Print("CurrentDistanceToTarget: " + DistanceToTarget, Color = FLinearColor::Yellow);
// // 		Print("CurrentLerpFraction: " + CurrentLerpFraction, Color = FLinearColor::Yellow);

// 		FTransform CurTargetTransform = GetTargetTransform();
// 		CurTargetTransform.NormalizeRotation();

// 		FTransform DesiredTransform;
// 		DesiredTransform.Blend(InitTransform, CurTargetTransform, CurrentLerpFraction);

// 		FTransform CurrentTransform = Player.GetActorTransform();
// 		CurrentTransform.NormalizeRotation();

//  		FVector DeltaTranslation = DesiredTransform.SubtractTranslations(CurrentTransform);
//  		FQuat MeshRotQuat_New = Math::MakeQuatFromX(DeltaTranslation.GetSafeNormal());

// 		const FVector DebugStart = InitTransform.GetLocation();
// 		const FVector DebugEnd = DesiredTransform.GetLocation();
// //  		System::DrawDebugLine(DebugStart, DebugEnd, FLinearColor::Green);

// 		if (CurrentState == EHookShotState::LandingStarted)
// 		{
// 			float LerpAlpha = CurrentLerpFraction;
// 			if (PlayerAnimParams_Landing_Enter.Animation != nullptr)
// 			{
// 				const float TimeUntilLand = FMath::Max(TotalEstimatedTravelTime - CurrentLerpTime, 0.f);
// 				const float LandingAnim_CurrentPlayTimeFraction = 1.f - (TimeUntilLand / PlayerAnimParams_Landing_Enter.Animation.SequenceLength);
// 				LerpAlpha = FMath::Clamp(LandingAnim_CurrentPlayTimeFraction, 0.f, 1.f);
// 			}

// 			const FQuat UpQuat = Math::MakeQuatFromX(FVector::UpVector);
// 			const FQuat ImpactNormalQuat = Math::MakeQuatFromX(HookTargetHitData.ImpactNormal);
// 			const FQuat SlerpedWorldUpQuat = FQuat::Slerp(UpQuat, ImpactNormalQuat, LerpAlpha);
// 			const FVector NewWorldUp = SlerpedWorldUpQuat.Vector();
//    			Player.ChangeActorWorldUp(NewWorldUp);
// // 			Player.ChangeActorWorldUp(NewWorldUp);

// 			const FQuat MeshRotQuat_Target = Player.GetActorTransform().GetRotation();
// 			const FQuat MeshRotQuat_Current = Player.Mesh.GetWorldTransform().GetRotation();
// 			const FQuat MeshRotQuat_Desired = FQuat::Slerp(MeshRotQuat_Current, MeshRotQuat_Target, LerpAlpha);
// 			MeshRotQuat_New = MeshRotQuat_Desired;
// 		}
// 		else if (CurrentState == EHookShotState::Landed)
// 		{
//   			MeshRotQuat_New = Player.GetActorTransform().GetRotation();
// 			const FQuat ImpactNormalQuat = Math::MakeQuatFromX(HookTargetHitData.ImpactNormal);
//    			Player.ChangeActorWorldUp(ImpactNormalQuat.Vector());
// 		}

// 		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"MatchWeaponHookShot");

// 		MoveData.ApplyDelta(DeltaTranslation);

// 		MoveData.OverrideStepDownHeight(0.f);
// 		MoveData.OverrideStepUpHeight(0.f);
// 		MoveData.AddActorToIgnore(WielderComp.GetMatchWeapon());
// 		MoveData.AddActorToIgnore(HookTargetHitData.GetActor());
// 		MoveData.AddComponentToIgnore(HookTargetHitData.GetComponent());
// 		MoveData.AddComponentToIgnore(GetHookComponent());
//  		MoveComp.Move(MoveData);

// //    		Player.Mesh.SetWorldRotation();
// // 		Player.RootOffsetComponent.OffsetRotationWithSpeed(MeshRotQuat_New.Rotator(), -1.f);
// //  		SmoothSetLocationAndRotation

// 		if (FMath::IsNearlyEqual(CurrentLerpFraction, 1.f))
// 		{
// 			if(CurrentState != EHookShotState::Landed)
// 			{
// // 				DoFortniteImpulse();
// //  				CurrentState == EHookShotState::Canceled;

// 				CurrentState = EHookShotState::Landed;
// 				Print("Reached Target at time : " + CurrentLerpTime,
// 					Color = FLinearColor::Green,
// 					Duration = 5.f
// 				);
// 			}
// 		}

// 		// cancel hookshot if we hit something on the way
//   		FMovementCollisionData HitData = MoveComp.GetImpacts();
// 		if (HitData.UpImpact.bBlockingHit 
// 			|| HitData.DownImpact.bBlockingHit 
// 			|| HitData.ForwardImpact.bBlockingHit)
// 		{
//  			CurrentState == EHookShotState::Canceled;
// 		}

// 	}

// 	bool DoHookTrace(FHitResult& TraceData)
// 	{
//  		const FVector Direction = Player.GetViewRotation().Vector();
//  		const FVector Origin = Player.GetViewLocation();
		
// 		/* Correct using auto-aim on our line trace. */
// 		FAutoAimLine Aim = GetAutoAimForTargetLine(
// 			Player,
// 			Origin,
// 			Direction,
// 			0.f,
// 			HookshotMaxDistance,
// 			bCheckVisibility = true
// 		);

// 		if (!Aim.AimLineDirection.IsNormalized())
// 			Aim.AimLineDirection.Normalize();

// 		bool bHit = TraceForHookHit(TraceData, Aim.AimLineStart, Aim.AimLineDirection);

// 		return bHit;
// 	}

// 	bool TraceForHookHit(FHitResult& TraceData, FVector Origin, FVector Direction)
// 	{
// 		auto WeaponToTraceFrom = WielderComp.GetMatchWeapon();
// 		const FVector TraceEnd = Origin + (Direction * HookshotMaxDistance);
// 		FVector TraceStart = FMath::ClosestPointOnInfiniteLine(
// 			Origin,
// 			TraceEnd,
// 			WeaponToTraceFrom.GetActorLocation()
// 		);

// 		TArray<AActor> ActorsToIgnore;
// 		ActorsToIgnore.Add(Player);
// 		ActorsToIgnore.Add(WeaponToTraceFrom);
// 		for (auto Match : WielderComp.Matches)
// 			ActorsToIgnore.Add(Match);

// 		/* Will only return first blocking hit. No overlaps. */
// 		const bool bHit = System::LineTraceSingle
// 		(
// 			TraceStart,
// 			TraceEnd,
// 			ETraceTypeQuery::WeaponTrace,
// 			false,
// 			ActorsToIgnore,
// 			EDrawDebugTrace::None,
// 			TraceData,
// 			true
// 		);

// 		return bHit;
// 	}

// 	FVector GetHookingDirection() const
// 	{
// 		return (HookTargetHitData.TraceEnd - HookTargetHitData.TraceStart).GetSafeNormal();
// 	}

// 	FVector GetDirectionToTarget() const
// 	{
// 		return (GetTargetLocation() - Player.GetActorLocation()).GetSafeNormal();
// 	}

// 	FVector GetTargetLocation() const
// 	{
// 		const FTransform TargetCompTransform = HookTargetHitData.GetComponent().GetWorldTransform();
// 		return TargetCompTransform.TransformPosition(HookImpactPoint_LOCAL);
// 	}

// 	FQuat GetTargetRotation() const
// 	{
// 		return Math::MakeQuatFromZ(-HookTargetHitData.ImpactNormal);
// 	}

// 	FTransform GetTargetTransform() const 
// 	{
// 		return FTransform(GetTargetRotation(), GetTargetLocation());
// 	}

// 	UHookCableComponent GetHookComponent() const 
// 	{
// 		return WielderComp.GetMatchWeapon().HookCable;
// 	}

// 	UFUNCTION(NetFunction)
// 	void NetInitData(FTransform ControlTransform, FRotator AimingRotation)
// 	{
// 		if (IsBlocked())
// 			return;

// 		InitTransform = ControlTransform;
// 		InitTransform.NormalizeRotation();
// 		InitAimRotation = AimingRotation;
// 		InitAimRotation.Normalize();
// 	}

// 	UFUNCTION()
// 	void ExitFlight()
// 	{
// 		// Check if we are trying to trigger ExitImpulse twice. 
// 		if (CurrentState == EHookShotState::ExitImpulseTriggered)
// 		{
// // 			ensure(false);
// 			return;
// 		}

//   		if (AutoExitImpulseTime > 0.f)
// 		{
// 			// Fortnite impulse will be triggered here 
// 			// if the flight was very short. 
// 			DoExitImpulse();

// 			// We cancel into fortnite (instead of staying tethered for a while) 
// 			// because are very close to impact at this point.
// 			//CurrentState == EHookShotState::Canceled;
// 			return;
// 		}

// 		ensure(CurrentState == EHookShotState::Flying);

// 		CurrentState = EHookShotState::LandingStarted;
// 		ApplyCameraSettings_Landing();
// 		PlayAnimation_Landing_Enter();
// 	}

// 	// Gameplay func
// 	//////////////////////////////////////////////////////////////////////////
// 	// Animation Func

//  	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
// 	FHazePlaySlotAnimationParams PlayerAnimParams_Flight_Enter;

//  	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
// 	FHazePlaySlotAnimationParams PlayerAnimParams_Flight_MH;

//  	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
// 	FHazePlaySlotAnimationParams PlayerAnimParams_Landing_Enter;

//  	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
// 	FHazePlaySlotAnimationParams PlayerAnimParams_Landing_MH;

// 	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
// 	FHazePlaySlotAnimationParams PlayerAnimParams_Impulse_Enter;

// 	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
// 	FHazePlaySlotAnimationParams PlayerAnimParams_Impulse_MH;

// 	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
// 	FHazePlaySlotAnimationParams PlayerAnimParams_Slide_Enter;

// 	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
// 	FHazePlaySlotAnimationParams PlayerAnimParams_Slide_Enter_AlreadySliding;

// 	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
// 	FHazePlaySlotAnimationParams PlayerAnimParams_Slide_MH;

// 	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
// 	FHazePlaySlotAnimationParams PlayerAnimParams_Slide_Exit;

//  	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
// 	FHazePlaySlotAnimationParams PlayerAnimParams_Fortnite_Enter;

//  	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
// 	FHazePlaySlotAnimationParams PlayerAnimParams_Fortnite_MH;

// 	void StopAllLoopingAnimations()
// 	{
// 		StopLoopingAnimation(PlayerAnimParams_Fortnite_Enter);
// 		StopLoopingAnimation(PlayerAnimParams_Fortnite_MH);
// 		StopLoopingAnimation(PlayerAnimParams_Flight_Enter);
// 		StopLoopingAnimation(PlayerAnimParams_Flight_MH);
// 		StopLoopingAnimation(PlayerAnimParams_Landing_Enter);
// 		StopLoopingAnimation(PlayerAnimParams_Landing_MH);
// 		StopLoopingAnimation(PlayerAnimParams_Impulse_Enter);
// 		StopLoopingAnimation(PlayerAnimParams_Impulse_MH);
// 		StopLoopingAnimation(PlayerAnimParams_Slide_Enter);
// 		StopLoopingAnimation(PlayerAnimParams_Slide_Enter_AlreadySliding);
// 		StopLoopingAnimation(PlayerAnimParams_Slide_MH);
// 		StopLoopingAnimation(PlayerAnimParams_Slide_Exit);
// 	}

// 	void StopLoopingAnimation(const FHazePlaySlotAnimationParams& InParams)
// 	{
// 		if (InParams.bLoop)
// 		{
// 			Player.StopAnimationByAsset(InParams.Animation, InParams.BlendTime);
// 		}
// 	}

// 	void BeginAnimationSequence() 
// 	{
// 		const float TimeUntilArrival = TotalEstimatedTravelTime - CurrentLerpTime;

// 		FHazePlaySlotAnimationParams Anim_Enter;
// 		FName Anim_MH = n"";

// 		float TimeNeededForSupermanAnim = 0.f;
// 		TimeNeededForSupermanAnim += PlayerAnimParams_Flight_Enter.Animation.SequenceLength;
// 		TimeNeededForSupermanAnim += PlayerAnimParams_Landing_Enter.Animation.SequenceLength;
// 		if (TimeNeededForSupermanAnim < TimeUntilArrival)
// 		{
// 			Anim_Enter = PlayerAnimParams_Flight_Enter;
// 			Anim_MH = n"PlayAnimation_Flight_MH";
// 		}
// 		else if (PlayerAnimParams_Impulse_Enter.Animation.SequenceLength < TimeUntilArrival)
// 		{
// 			Anim_Enter = PlayerAnimParams_Impulse_Enter;
// 			Anim_MH = n"PlayAnimation_Impulse_MH";
// 		}
// 		else if(IsAnySlideAnimationPlaying())
// 		{
// 			Anim_Enter = PlayerAnimParams_Slide_Enter_AlreadySliding;
// 			Anim_MH = n"PlayAnimation_Slide_MH";
// 		}
// 		else 
// 		{
// 			Anim_Enter = PlayerAnimParams_Slide_Enter;
// 			Anim_MH = n"PlayAnimation_Slide_MH";
// 		}

// 		//////////////////////////////////////////////////////////////////////////
// 		// @TODO: Place this elsewhere once we refactor 
// 		ApplyCameraSettings_Flight();
// 		//////////////////////////////////////////////////////////////////////////

// 		FHazeAnimationDelegate OnBlendingIn_PlayerImpulse;
// 		FHazeAnimationDelegate OnBlendingOut_PlayerImpulse;
// 		OnBlendingOut_PlayerImpulse.BindUFunction(this, Anim_MH);
// 		Player.PlaySlotAnimation(
// 			OnBlendingIn_PlayerImpulse,
// 			OnBlendingOut_PlayerImpulse,
// 			Anim_Enter
// 		);

// 		// figure out when we should exit flight and branch out into 
// 		// either landing animation or fortnite impulse
// 		// @TODO: this shouldn't apply to all animations. 
// 		// But we'll put it here to ensure consistency.
// 		float TimeUntilWeExitFlight = TotalEstimatedTravelTime;
// 		TimeUntilWeExitFlight -= PlayerAnimParams_Landing_Enter.Animation.SequenceLength;
// 		TimeUntilWeExitFlight -= CurrentLerpTime;
// 		ExitFlightTimer = System::SetTimer(
// 			this,
// 			n"ExitFlight",
// 			FMath::Max(TimeUntilWeExitFlight, KINDA_SMALL_NUMBER),
// 			bLooping=false
// 		);

// 	}

// 	bool IsAnySlideAnimationPlaying() 
// 	{
// 		if (Player.IsPlayingAnimAsSlotAnimation(PlayerAnimParams_Slide_Enter.Animation))
// 			return true;
// 		else if (Player.IsPlayingAnimAsSlotAnimation(PlayerAnimParams_Slide_MH.Animation))
// 			return true;
// 		else if (Player.IsPlayingAnimAsSlotAnimation(PlayerAnimParams_Slide_Enter_AlreadySliding.Animation))
// 			return true;
// 		else if (Player.IsPlayingAnimAsSlotAnimation(PlayerAnimParams_Slide_Enter_AlreadySliding.Animation))
// 			return true;
// 		else if (Player.IsPlayingAnimAsSlotAnimation(PlayerAnimParams_Slide_Exit.Animation))
// 			return true;
// 		else
// 			return false;
// 	}

// 	UFUNCTION()
// 	void PlayAnimation_Fortnite_Enter()
// 	{
// 		if (!IsActive() || IsBlocked())
// 			return;

// 		FHazeAnimationDelegate DummyBlendIn;
// 		FHazeAnimationDelegate DummyBlendOut;
// 		Player.PlaySlotAnimation(DummyBlendIn, DummyBlendOut, PlayerAnimParams_Fortnite_Enter);
// 	}

// 	UFUNCTION()
// 	void PlayAnimation_Slide_MH()
// 	{
// 		if (!IsActive() || IsBlocked())
// 			return;

// 		FHazeAnimationDelegate DummyBlendIn;
// 		FHazeAnimationDelegate DummyBlendOut;
// 		Player.PlaySlotAnimation(DummyBlendIn, DummyBlendOut, PlayerAnimParams_Slide_MH);
// 	}

// 	UFUNCTION()
// 	void PlayAnimation_Impulse_MH()
// 	{
// 		if (!IsActive() || IsBlocked())
// 			return;

// 		FHazeAnimationDelegate DummyBlendIn;
// 		FHazeAnimationDelegate DummyBlendOut;
// 		Player.PlaySlotAnimation(DummyBlendIn, DummyBlendOut, PlayerAnimParams_Impulse_MH);
// 	}

// 	UFUNCTION()
// 	void PlayAnimation_Slide_Exit()
// 	{
// 		if (!IsActive() || IsBlocked())
// 			return;

// 		FHazeAnimationDelegate DummyBlendIn;
// 		FHazeAnimationDelegate DummyBlendOut;
// 		Player.PlaySlotAnimation(DummyBlendIn, DummyBlendOut, PlayerAnimParams_Slide_Exit);
// 	}


// 	UFUNCTION()
// 	void PlayAnimation_Flight_MH() 
// 	{
// 		if (!IsActive() || IsBlocked())
// 			return;

// 		FHazeAnimationDelegate DummyBlendIn;
// 		FHazeAnimationDelegate DummyBlendOut;
// 		Player.PlaySlotAnimation(DummyBlendIn, DummyBlendOut, PlayerAnimParams_Flight_MH);
// 	}

// 	UFUNCTION()
// 	void PlayAnimation_Landing_Enter()
// 	{
// 		if (!IsActive() || IsBlocked())
// 			return;

// 		FHazeAnimationDelegate DUMMY;
// 		FHazeAnimationDelegate BlendingOut;
// 		BlendingOut.BindUFunction(this, n"PlayAnimation_Landing_MH");
// 		Player.PlaySlotAnimation(DUMMY, BlendingOut, PlayerAnimParams_Landing_Enter);
// 	}

// 	UFUNCTION()
// 	void PlayAnimation_Landing_MH()
// 	{
// 		if (!IsActive() || IsBlocked())
// 			return;

// 		FHazeAnimationDelegate DummyBlendIn;
// 		FHazeAnimationDelegate DummyBlendOut;
// 		Player.PlaySlotAnimation(DummyBlendIn, DummyBlendOut, PlayerAnimParams_Landing_MH);
// 	}

// 	// Animation func
// 	//////////////////////////////////////////////////////////////////////////
// 	// Camera func

// 	UPROPERTY(Category = "Camera")
// 	UHazeCameraSpringArmSettingsDataAsset CameraSettings_Flight;

// 	/* How fast the camera settings will be blended in*/
// 	UPROPERTY(Category = "Camera")
// 	float CameraSettingsBlendInTime_Flight = 0.5f;

// 	UPROPERTY(Category = "Camera")
// 	UHazeCameraSpringArmSettingsDataAsset CameraSettings_Fornite;

// 	/* How fast the camera settings will be blended in*/
// 	UPROPERTY(Category = "Camera")
// 	float CameraSettingsBlendInTime_Fortnite = 0.5f;

// 	UPROPERTY(Category = "Camera")
// 	UHazeCameraSpringArmSettingsDataAsset CameraSettings_Landing;

// 	/* How fast the camera settings will be blended in*/
// 	UPROPERTY(Category = "Camera")
// 	float CameraSettingsBlendInTime_Landing = 0.5f;

// 	UPROPERTY(Category = "Camera")
// 	TSubclassOf<UCameraShakeBase> CameraShake_Flight;

// 	UPROPERTY(Category = "Camera")
// 	TSubclassOf<UCameraShakeBase> CameraShake_Fortnite;

// 	UPROPERTY(Category = "Camera")
// 	TSubclassOf<UCameraShakeBase> CameraShake_Landing;

// 	void ApplyCameraSettings_Landing()
// 	{
// 		auto BlendSettings = FHazeCameraBlendSettings();
// 		BlendSettings.BlendTime = CameraSettingsBlendInTime_Landing;
// 		Player.PlayCameraShake(CameraShake_Landing);
// 		Player.ApplyCameraSettings
// 		(
// 			CameraSettings_Landing,
// 			BlendSettings,
// 			CameraSettings_Landing,
// 			EHazeCameraPriority::Maximum
// 		);
// 	}

// 	void ClearCameraSettings_Landing()
// 	{
// 		Player.ClearCameraSettingsByInstigator(CameraSettings_Landing);
// 	}

// 	void ApplyCameraSettings_Fortnite()
// 	{
// 		if (!IsActioning(ActionNames::WeaponAim))
// 			return;

// 		auto BlendSettings = FHazeCameraBlendSettings();
// 		BlendSettings.BlendTime = CameraSettingsBlendInTime_Fortnite;
// 		Player.PlayCameraShake(CameraShake_Fortnite);
// 		Player.ApplyCameraSettings
// 		(
// 			CameraSettings_Fornite,
// 			BlendSettings,
// 			CameraSettings_Fornite,
// 			EHazeCameraPriority::Maximum
// 		);
// 	}

// 	void ClearCameraSettings_Fortnite()
// 	{
// 		Player.ClearCameraSettingsByInstigator(CameraSettings_Fornite);
// 	}

// 	void ApplyCameraSettings_Flight()
// 	{
// 		auto BlendSettings = FHazeCameraBlendSettings();
// 		BlendSettings.BlendTime = CameraSettingsBlendInTime_Flight;
// 		Player.ApplyCameraSettings
// 		(
// 			CameraSettings_Flight,
// 			BlendSettings,
// 			CameraSettings_Flight,
// 			EHazeCameraPriority::High
// 		);
// 	}

// 	void ClearCameraSettings_Flight()
// 	{
// 		Player.ClearCameraSettingsByInstigator(CameraSettings_Flight);
// 	}

// 	void ClearAllCameraSettings() 
// 	{
// 		ClearCameraSettings_Flight();
// 		ClearCameraSettings_Landing();
// 		ClearCameraSettings_Fortnite();
// 	}

// }



























