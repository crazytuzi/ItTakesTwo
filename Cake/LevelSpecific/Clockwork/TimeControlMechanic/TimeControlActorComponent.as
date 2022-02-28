import Peanuts.Outlines.Outlines;
import Peanuts.Outlines.Stencil;
import Cake.LevelSpecific.Clockwork.Widgets.TimeControlAbilityWidget;
import Vino.Time.ActorTimeDilationStatics;

import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;
import Vino.ActivationPoint.ActivationPointStatics;

import void OnPointTargeted(UTimeControlActorComponent) from "Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlLinkedActor";
import void OnPointTargetLost(UTimeControlActorComponent) from "Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlLinkedActor";
import bool CanActivateTimeComponent(AHazePlayerCharacter, const UTimeControlActorComponent) from "Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlComponent";
import void OnTimeComponentCameraSettingsChanged(UTimeControlActorComponent TimeComp) from "Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlComponent";
import Cake.LevelSpecific.Clockwork.Actors.ReversableBreakable;

enum ETimeControlActorEaseFunction
{  
    Linear,
	SinusoidalIn,
	SinussoidalOut,
	SinussoidalInOut,
	ExpoIn,
	ExpoOut,
	ExpoInOut,
	CircularIn,
	CircularOut,
	CircularInOut,
	CustomCurve
};

enum ETimeControlOutlineActivation
{  
    None,
	ActivatePassive,
	ActivateActive,
	Inactivate,
};

enum ETimeControlActivationPointValidationType
{
	Default,
	PreferHorizontal
};

enum ETimeControlPlayerAction
{
	Nothing,
	ReverseTime,
	ProgressTime,
	HoldTime,
};

enum ETimeControlCrumbType
{
	Increasing,
	Decreasing,
	Static,
	Unknown,
	Wrapping
};

struct FTimeControlCrumb
{
	float ControlDuration;
	float RawPointInTimeAlpha;
	ETimeControlCrumbType CrumbType = ETimeControlCrumbType::Static;
	bool bIsBeingTimeControlled = false;

	void ConsumeDuration(float& Delta)
	{
		float Consume = FMath::Min(ControlDuration, Delta);
		ControlDuration -= Consume;
		Delta -= Consume;
	}
};

event void FTimeControlActorSignatureFloat(float PointInTime);
event void FTimeControlActorSignatureInt(int TimeDilationStep);
event void FTimeControlActorSignatureNoValues();

UCLASS(HideCategories = "Cooking Replication Input Actor Capability LOD")
class UTimeControlActorComponent : UHazeTimeActivationPoint
{	
	default ValidationType = EHazeActivationPointActivatorType::Cody;
	default ValidationIdentifier = EHazeActivationPointIdentifierType::LevelSpecific;
	default InitializeDistance(EHazeActivationPointDistanceType::Visible, 10000.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 5000.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 2500.f); 

	default WidgetClass = Asset("/Game/Blueprints/LevelSpecific/Clockwork/HUD/WBP_TimeControlWidget.WBP_TimeControlWidget_C");
		
	/* --- Time Control Ability Properties --- */

	// Whether the time control should affect the player camera at all
	UPROPERTY(Category = "Time Control Interaction")
	bool bAffectsCamera = true;

	// The alpha value of the current point in time
	UPROPERTY(Category = "Time Control Properties", Meta=(ClampMin = 0.f, ClampMax = 1.f))
	float StartingPointInTime = 0.f;

	UPROPERTY(Category = "Time Control Properties", Meta=(BlueprintSetter = "ChangeCanBeTimeControlled"))
	bool bCanBeTimeControlled = true;

	UPROPERTY(Category = "Time Control Properties", Meta = (EditCondition = "!bAddConstantReverse"))
	bool bAddConstantProgression = false;

	UPROPERTY(Category = "Time Control Properties", Meta = (EditCondition = "!bAddConstantProgression"))
	bool bAddConstantReverse = false;

	UPROPERTY(Category = "Time Control Properties", Meta = (EditCondition = "bAddConstantProgression", EditConditionHides), AdvancedDisplay)
	bool bFlipFlopProgress = false;

	// If set, the constant progression happens while the component is being controlled instead of when it isn't
	UPROPERTY(Category = "Time Control Properties", Meta = (EditCondition = "bAddConstantProgression || bAddConstantReverse", EditConditionHides))
	bool bConstantProgressionOnlyWhenControlled = false;

	UPROPERTY(Category = "Time Control Properties")
	float ConstantIncreaseValue = 0.f;

	// Sets how fast the point of time is beging changed
	UPROPERTY(Category = "Time Control Properties")
	float TimeStepMultiplier = 1.f;

	// If set, the player will always advance fully to 1.0 before being allowed to go backwards again
	UPROPERTY(Category = "Time Control Properties")
	bool bForceFullyAdvance = false;

	// If set, the player will always reverse fully to 0.0 before being allowed to go forwards again
	UPROPERTY(Category = "Time Control Properties")
	bool bForceFullyReverse = false;

	// Camera to switch to when controlling this component
	UPROPERTY(Category = "Time Control Camera")
	AHazeCameraActor ControlCamera;

	// Additional cameras that are possible to use when controlling this object. The closest one to the player will be chosen.
	UPROPERTY(Category = "Time Control Camera", AdvancedDisplay)
	TArray<AHazeCameraActor> AdditionalPossibleCameras;

	// Camera settings to use when controlling this component
	UPROPERTY(Category = "Time Control Camera")
	UHazeCameraSettingsDataAsset ControlCameraSettings;
	default ControlCameraSettings = Asset("/Game/Blueprints/LevelSpecific/Clockwork/CameraSettings/DA_CamSettings_TimeControlAbility.DA_CamSettings_TimeControlAbility");

	// Blend time to use when applying this component's camera settings
	UPROPERTY(Category = "Time Control Camera")
	float ControlCameraSettingsBlendTime = 3.f;

	UPROPERTY(Category = "Time Control Camera")
	float ControlCameraSettingsBlendOutTime = -1.f;

	// Offset from the component to apply when setting a point of interest
	UPROPERTY(Category = "Time Control Camera", Meta = (MakeEditWidget))
	FTransform PointOfInterestOffset;

	// Blend time to use with the point of interest for this component
	UPROPERTY(Category = "Time Control Camera")
	float PointOfInterestBlendTime = 0.5f;

	private float PointInTimeLastTick = 0.f;

	UPROPERTY(Category = "Time Control Properties")
	bool TimePositionChanged;

	private float CurrentProgressSpeed = 0.f;
	private ETimeControlPlayerAction CurrentPlayerAction = ETimeControlPlayerAction::Nothing;
	ETimeControlPlayerAction ForcedPlayerAction = ETimeControlPlayerAction::Nothing;

	/* --- Delegates --- */
	UPROPERTY()
	FTimeControlActorSignatureNoValues TimeFullyReversedEvent;

	UPROPERTY()
	FTimeControlActorSignatureNoValues TimeFullyProgressedEvent;

	UPROPERTY()
	FTimeControlActorSignatureFloat TimeIsChangingEvent;

	UPROPERTY()
	FTimeControlActorSignatureNoValues CodyStoppedInteractionEvent;

	UPROPERTY()
	FTimeControlActorSignatureNoValues StartedProgressingTime;

	UPROPERTY()
	FTimeControlActorSignatureNoValues StartedReversingTime;

	UPROPERTY()
	FTimeControlActorSignatureNoValues StartedHoldingTimeStill;

	/* --- General Outline Settings --- */

	UPROPERTY()
	AReversableBreakableActor ReversableBreakable;

	/* --- Ease Propery. Determines the Point in Time Curve --- */
	UPROPERTY(Category = "Curve Settings")
	ETimeControlActorEaseFunction EaseFunction;

	// Curve to use when custom curve is specified as the ease function
	UPROPERTY(Category = "Curve Settings", Meta = (EditCondition = "EaseFunction == ETimeControlActorEaseFunction::CustomCurve", EditConditionHides))
	UCurveFloat EaseCustomCurve;

	// Whether to use acceleration for this time control
	UPROPERTY(Category = "Curve Settings")
	bool bUseAcceleration = false;

	// Acceleration to use for this time control
	UPROPERTY(Category = "Curve Settings", Meta = (EditCondition = "bUseAcceleration", EditConditionHides))
	float TimeControlAcceleration = 2.f;

	// Whether to use acceleration for this time control
	UPROPERTY(Category = "Curve Settings")
	bool bUseDeceleration = false;

	// Deceleration to use for this time control
	UPROPERTY(Category = "Curve Settings", Meta = (EditCondition = "bUseDeceleration", EditConditionHides))
	float TimeControlDeceleration = 2.f;
	
	AHazeActor CompOwner;

	UPROPERTY(Category = "Activation Point")
	ETimeControlActivationPointValidationType TimeControlActivationPointValidationType = ETimeControlActivationPointValidationType::Default;

	bool bHasBroadcastedDelegate = false;
	bool bIsCurrentlyBeingTimeControlled = false;
	
	private TArray<UPrimitiveComponent> ParentComponentArray;
	private TArray<UTimeControlActorComponent> LinkedComponents;
	private UTimeControlActorComponent LinkedMasterComp;
	private FVector OriginalRelativeLocation;
	private float RawPointInTimeAlpha = 0.f;

	private TArray<AActor> Disablers;

	private const float SyncTime = 0.1f;
	private TArray<FTimeControlCrumb> Crumbs;
	private FTimeControlCrumb ActiveCrumb;
	private bool bIsFrozenInCrumbTrail = true;
	private float TotalStaticValueTimer = 0.f;
	private bool bIsCrumbTrailSleeping = true;
	private bool bPreviousCrumbIsBeingControlled = false;
	private ETimeControlCrumbType PreviousCrumbDirection = ETimeControlCrumbType::Static;

	// Prevent the player from controlling this until it is enabled again
	UFUNCTION()
	void DisableTimeControl(AActor Disabler)
	{
		if (LinkedMasterComp != nullptr)
		{
			LinkedMasterComp.DisableTimeControl(Disabler);
			return;
		}

		Disablers.AddUnique(Disabler);
	}

	// Remove a previous disable preventing the player from time controlling this
	UFUNCTION()
	void EnableTimeControl(AActor Disabler)
	{
		if (LinkedMaster != nullptr)
		{
			LinkedMasterComp.EnableTimeControl(Disabler);
			return;
		}

		Disablers.RemoveSwap(Disabler);
	}

	UFUNCTION()
	void ChangeCanBeTimeControlled(bool bNewValue)
	{
		bool bPrevValue = bCanBeTimeControlled;
		bCanBeTimeControlled = bNewValue;
		
		if (bPrevValue && !bNewValue)
		{
			SetTimeWarpEffect(ETimeWarStencilState::Nothing);
		}
		else if (!bPrevValue && bNewValue)
		{
			SetTimeWarpEffect(ETimeWarStencilState::Idle);
		}
	}

	UFUNCTION()
	void ChangeUsedCameraSettings(UHazeCameraSettingsDataAsset NewCameraSettings)
	{
		ControlCameraSettings = NewCameraSettings;

		if (bIsCurrentlyBeingTimeControlled)
			OnTimeComponentCameraSettingsChanged(this);
	}

	bool IsTimeControlDisabled() const
	{
		if (LinkedMaster != nullptr)
			return LinkedMasterComp.IsTimeControlDisabled();
		return Disablers.Num() != 0;
	}

	bool HasStaticCamera()
	{
		return ControlCamera != nullptr || AdditionalPossibleCameras.Num() != 0;
	}

	AHazeCameraActor GetStaticCamera(AHazePlayerCharacter Player)
	{
		if (ControlCamera != nullptr || AdditionalPossibleCameras.Num() != 0)
		{
			AHazeCameraActor ClosestCamera = nullptr;
			float ClosestDistance = MAX_flt;

			if (ControlCamera != nullptr)
			{
				ClosestCamera = ControlCamera;
				ClosestDistance = ClosestCamera.ActorLocation.Distance(Player.ViewLocation);
			}

			for (AHazeCameraActor Camera : AdditionalPossibleCameras)
			{
				if (Camera == nullptr)
					continue;
				float Dist = Camera.ActorLocation.Distance(Player.ViewLocation);
				if (Dist < ClosestDistance)
				{
					ClosestCamera = Camera;
					ClosestDistance = Dist;
				}
			}

			if (ClosestCamera != nullptr)
				return ClosestCamera;
		}
		return nullptr;
	}
	
	// Widget Ref
	UTimeControlAbilityWidget TimeControlWidget;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
	}

	// This will make this component controlled by the master
	void LinkWithMasterComponent(UTimeControlActorComponent MasterComp, bool bIndividualTargeting)
	{
		LinkedMaster = Cast<AHazeActor>(MasterComp.GetOwner());
		MasterComp.LinkedSlaves.Add(Cast<AHazeActor>(GetOwner()));
		if(bIndividualTargeting == false)
		{
			ChangeValidActivator(EHazeActivationPointActivatorType::None);
		}
	}

	void UnlinkAllSlaves()
	{
		for(AHazeActor Slave : LinkedSlaves)
		{
			if (Slave == nullptr)
				continue;

			UTimeControlActorComponent SlaveComp = UTimeControlActorComponent::Get(Slave);
			if(SlaveComp != nullptr)
			{
				SlaveComp.LinkedMaster = nullptr;
				SlaveComp.ChangeValidActivator(EHazeActivationPointActivatorType::Cody);
			}
		}
		
		LinkedSlaves.Empty();	
	}
	
	UFUNCTION(BlueprintOverride)
	void OnPointTargetedBy(AHazePlayerCharacter Player)
	{
		if(LinkedMaster != nullptr)
		{
			OnPointTargeted(this);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnPointTargetingLostBy(AHazePlayerCharacter Player)
	{
		if(LinkedMaster != nullptr)
		{
			OnPointTargetLost(this);
		}		
	}

	UFUNCTION(BlueprintOverride)
	void OnPointActivatedBy(AHazePlayerCharacter Player)
	{
		if(LinkedComponents.Num() > 0)
		{
			OnPointTargeted(this);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnPointDeactivatedBy(AHazePlayerCharacter Player)
	{
		if(LinkedComponents.Num() > 0)
		{
			OnPointTargetLost(this);
		}	
	}

	FVector GenerateLinkedMiddlePosition()const
	{
		if(LinkedComponents.Num() > 0)
		{
			FVector MiddlePosition = FVector::ZeroVector;
			for(int i = 0; i < LinkedComponents.Num(); ++i)
			{	
				MiddlePosition += LinkedComponents[i].GetWorldLocation();
			}

			return MiddlePosition /= LinkedComponents.Num();
		}
		else
		{
			return GetWorldLocation();
		}
	}

	// This function implements how the magnets are displayed and grabable
	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{	
		if(Query.DistanceType == EHazeActivationPointDistanceType::OutOfRange)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		if(bCanBeTimeControlled == false)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		if(CanActivateTimeComponent(Player, this) == false)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		if(Query.DistanceType == EHazeActivationPointDistanceType::Visible)
			return EHazeActivationPointStatusType::Valid;

		// We test the free sight
		FHazeTraceParams TraceSettings;
		InitializeTraceSettings(Player, Query, TraceSettings);

		FHitResult HitResult;
		EHazeActivationAsyncStatusType TraceResult = Query.AsyncTrace(Player, TraceSettings, HitResult);

		if(TraceResult == EHazeActivationAsyncStatusType::NoData)
			return EHazeActivationPointStatusType::Invalid;

		if(TraceResult == EHazeActivationAsyncStatusType::TraceFoundCollision)
			return EHazeActivationPointStatusType::Invalid;
	
		return EHazeActivationPointStatusType::Valid;
	}

	void InitializeTraceSettings(AHazePlayerCharacter Player, FHazeQueriedActivationPoint QueryPoint, FHazeTraceParams& Settings) const
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		
		Settings.InitWithTraceChannel(ETraceTypeQuery::Visibility);
		Settings.IgnoreActor(Game::May);
		Settings.IgnoreActor(Game::Cody);
		Settings.SetToLineTrace();

		// Setup Ignores
		AActor PointOwner = QueryPoint.Point.GetOwner();
		Settings.IgnoreActor(PointOwner);

		for (UTimeControlActorComponent LinkedComp : LinkedComponents)
		{
			Settings.IgnoreActor(LinkedComp.Owner);
		}
		
		AActor AttachParentActor = PointOwner.GetAttachParentActor();
		if (AttachParentActor != nullptr)
			Settings.IgnoreActor(AttachParentActor);

		UHazeActivationPoint ActivePoint = Player.GetActivePoint();
		if (ActivePoint != nullptr)
			Settings.IgnoreActor(ActivePoint.GetOwner());

		// Setup trace target
		Settings.From = Player.ViewLocation;

		// Setup to location
		Settings.To = QueryPoint.Transform.GetLocation();
	}

	UFUNCTION(BlueprintOverride)
	float SetupValidationScoreAlpha(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query, float CompareDistanceAlpha) const
	{	
		const float ScoreAlpha = ActivationPointsStatics::CalculateValidationScoreAlpha(Player, Query, CompareDistanceAlpha);

		if (TimeControlActivationPointValidationType == ETimeControlActivationPointValidationType::PreferHorizontal)
		{
			float ZValue = Query.Transform.Location.Z - Player.GetActorLocation().Z;

			if (ZValue > 500.f)
			{
				ZValue = FMath::Min(ZValue / Query.Point.GetDistance(EHazeActivationPointDistanceType::Selectable), 1.f);
				return (1.f - ZValue) /*+ (ScoreAlpha * 0.25f)*/;
			}
		}
		
		return ScoreAlpha;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CompOwner = Cast<AHazeActor>(Owner);
		AHazePlayerCharacter Player = Game::GetCody();

		// Set controlling side
		Network::SetActorControlSide(Owner, Player);

		// Link up all the picked actors
		LinkedComponents.Empty();
		if(LinkedMaster == nullptr)
		{
			for(AHazeActor Slave : LinkedSlaves)
			{
				if (Slave == nullptr)
					continue;
				
				UTimeControlActorComponent LinkedComponent = UTimeControlActorComponent::Get(Slave);
				if(LinkedComponent != nullptr)
				{
					LinkedComponents.Add(LinkedComponent);
				}
			}

			// Activationpoints don't tick by default
			SetComponentTickEnabled(true);

			RawPointInTimeAlpha = StartingPointInTime;
			ActiveCrumb.RawPointInTimeAlpha = StartingPointInTime;
			OriginalRelativeLocation = RelativeLocation;
			SetPointInTimeInternal(GetPointInTime());
		}
		else
		{
			LinkedMasterComp = UTimeControlActorComponent::Get(LinkedMaster);
		}
		
		//Get all StaticMeshComponent from AttachParentActor
		TArray <UActorComponent> TempArray;
		TempArray = Owner.GetComponentsByClass(UPrimitiveComponent::StaticClass());
		
		for (UActorComponent Comp : TempArray)
		{
			UPrimitiveComponent MeshComp;
			MeshComp = Cast<UPrimitiveComponent>(Comp);
			if (MeshComp != nullptr)
				ParentComponentArray.Add(MeshComp);
		}
		
		if (bCanBeTimeControlled)
			SetTimeWarpEffect(ETimeWarStencilState::Idle);
	}

	void SetTimeWarpEffect(ETimeWarStencilState State)
	{
		if(ReversableBreakable != nullptr)
			ReversableBreakable.SetTimeWarp(State);
		for (UPrimitiveComponent Comp : ParentComponentArray)
			SetTimewarpNew(Comp, State);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{		
		// Slave components need to wait for the master
		if (LinkedMaster == nullptr)
		{
			TickPointInTime(DeltaTime);
		}		
	}
	
	void ChangePlayerAction(ETimeControlPlayerAction Action)
	{		
		if (HasControl() && Action != CurrentPlayerAction)
			NetChangePlayerAction(Action);
	}

	UFUNCTION(NetFunction)
	private void NetChangePlayerAction(ETimeControlPlayerAction Action)
	{
		CurrentPlayerAction = Action;
		switch (CurrentPlayerAction)
		{
			case ETimeControlPlayerAction::HoldTime:
				StartedHoldingTimeStill.Broadcast();
			break;
			case ETimeControlPlayerAction::ProgressTime:
				StartedProgressingTime.Broadcast();
			break;
			case ETimeControlPlayerAction::ReverseTime:
				StartedReversingTime.Broadcast();
			break;
		}
	}

	UFUNCTION(BlueprintPure)
	float GetPointInTime() const property
	{	
		if (LinkedMasterComp != nullptr)
			return LinkedMasterComp.GetPointInTime();
		else if (EaseFunction != ETimeControlActorEaseFunction::Linear)
			return EasePointInTime(EaseFunction, RawPointInTimeAlpha);
		else 	
			return RawPointInTimeAlpha;
	}

	// Point in time can still be going forward from constant progression even if this returns false
	UFUNCTION(BlueprintPure, Meta = (DisplayName = "Is Time Not Moving By Player"))
	bool IsTimeStandingStill()
	{
		return CurrentPlayerAction == ETimeControlPlayerAction::Nothing
			|| CurrentPlayerAction == ETimeControlPlayerAction::HoldTime;
	}

	UFUNCTION(BlueprintPure)
	bool IsTimeMovingForwardForAnyReason()
	{
		switch (CurrentPlayerAction)
		{
			case ETimeControlPlayerAction::Nothing:
			case ETimeControlPlayerAction::HoldTime:
				if (bIsCurrentlyBeingTimeControlled == bConstantProgressionOnlyWhenControlled
					&& bAddConstantProgression && RawPointInTimeAlpha < 1.f)
				{
					return true;
				}
			break;
			case ETimeControlPlayerAction::ProgressTime:
				return true;
		}

		return false;
	}

	// Only true if time is being progressed by active player control
	UFUNCTION(BlueprintPure, Meta = (DisplayName = "Is Time Progressing By Player"))
	bool IsTimeProgressing()
	{
		return CurrentPlayerAction == ETimeControlPlayerAction::ProgressTime;
	}

	// Only true if time is being progressed by active player control
	UFUNCTION(BlueprintPure, Meta = (DisplayName = "Is Time Reversing By Player"))
	bool IsTimeReversing()
	{
		return CurrentPlayerAction == ETimeControlPlayerAction::ReverseTime;
	}

	// Only true if time is being progressed by active player control
	UFUNCTION(BlueprintPure, Meta = (DisplayName = "Is Time Moving By Player"))
	bool IsTimeMoving()
	{
		return CurrentPlayerAction == ETimeControlPlayerAction::ProgressTime
			|| CurrentPlayerAction == ETimeControlPlayerAction::ReverseTime;
	}

	private void TickPointInTime(float DeltaTime)
	{	
		if (bCanBeTimeControlled)
		{
			float TargetProgressSpeed = CurrentProgressSpeed;
			bool bTargetProgressIsDeceleration = false;
			switch (CurrentPlayerAction)
			{
				case ETimeControlPlayerAction::Nothing:
				case ETimeControlPlayerAction::HoldTime:
					if (bIsCurrentlyBeingTimeControlled == bConstantProgressionOnlyWhenControlled
						&& (bAddConstantProgression || bAddConstantReverse))
					{
						if (bAddConstantProgression)
							TargetProgressSpeed = ConstantIncreaseValue;
						else
							TargetProgressSpeed = -ConstantIncreaseValue;
						bTargetProgressIsDeceleration = bConstantProgressionOnlyWhenControlled;
					}
					else
					{
						TargetProgressSpeed = 0.f;
						bTargetProgressIsDeceleration = true;
					}
				break;
				case ETimeControlPlayerAction::ProgressTime:
					TargetProgressSpeed = TimeStepMultiplier;
					if (FMath::Sign(TargetProgressSpeed) != FMath::Sign(CurrentProgressSpeed))
						CurrentProgressSpeed = 0.f;
				break;
				case ETimeControlPlayerAction::ReverseTime:
					TargetProgressSpeed = -TimeStepMultiplier;
					if (FMath::Sign(TargetProgressSpeed) != FMath::Sign(CurrentProgressSpeed))
						CurrentProgressSpeed = 0.f;
				break;
			}

			if (bUseAcceleration && !bTargetProgressIsDeceleration)
			{
				CurrentProgressSpeed = FMath::FInterpConstantTo(
					CurrentProgressSpeed,
					TargetProgressSpeed,
					DeltaTime, TimeControlAcceleration);
			}
			else if (bUseDeceleration && bTargetProgressIsDeceleration)
			{
				CurrentProgressSpeed = FMath::FInterpConstantTo(
					CurrentProgressSpeed,
					TargetProgressSpeed,
					DeltaTime, TimeControlDeceleration);
			}
			else
			{
				CurrentProgressSpeed = TargetProgressSpeed;
			}
		}
		else
		{
			CurrentProgressSpeed = 0.f;
		}

		if (LinkedMasterComp == nullptr)
		{
			if (HasControl())
			{
				if (CurrentProgressSpeed != 0.f)
					RawPointInTimeAlpha = FMath::Clamp(RawPointInTimeAlpha + (CurrentProgressSpeed * DeltaTime), 0.f, 1.f);
				SendPointInTimeCrumbs(DeltaTime);
			}
			else
			{
				float PrevPointInTime = RawPointInTimeAlpha;
				UpdatePointInTimeFromCrumbs(DeltaTime);
			}
		}

		const float TimePosition = GetPointInTime();
		
		TimePositionChanged = TimePosition != PointInTimeLastTick;
		if (TimePositionChanged)
		{
			SetPointInTimeInternal(TimePosition);
		}

		if(HasControl())
		{
			if (bIsCurrentlyBeingTimeControlled)
			{
				// Add forced actions if the time control component wants them
				if (bForceFullyAdvance && TimePosition < 1.f && CurrentPlayerAction == ETimeControlPlayerAction::ProgressTime)
					ForcedPlayerAction = ETimeControlPlayerAction::ProgressTime;
				if (bForceFullyReverse && TimePosition > 0.f && CurrentPlayerAction == ETimeControlPlayerAction::ReverseTime)
					ForcedPlayerAction = ETimeControlPlayerAction::ReverseTime;

				// Remove forced actions when we reach the appropriate terminus
				if (TimePosition >= 1.f && ForcedPlayerAction == ETimeControlPlayerAction::ProgressTime)
					ForcedPlayerAction = ETimeControlPlayerAction::Nothing;
				if (TimePosition <= 0.f && ForcedPlayerAction == ETimeControlPlayerAction::ReverseTime)
					ForcedPlayerAction = ETimeControlPlayerAction::Nothing;
			}

			if (TimePosition == 0.f && !bHasBroadcastedDelegate)
			{
				NetBroadcastTimeTimeReached(TimePosition);
				if (bFlipFlopProgress)
					FlipProgressDirection();
			}
			else if (TimePosition == 1.f && !bHasBroadcastedDelegate)
			{
				NetBroadcastTimeTimeReached(TimePosition);
				if (bFlipFlopProgress)
					FlipProgressDirection();
			}	
		}
		
	}
	

	void SetPointInTimeInternal(float NewPointInTime)
	{
		if (NewPointInTime >= 0.f && NewPointInTime <= 1.f)
		{
			TimeIsChangingEvent.Broadcast(NewPointInTime);		
			bHasBroadcastedDelegate = false;
		}
		
		PointInTimeLastTick = NewPointInTime;

		// Update Links
		for (UTimeControlActorComponent LinkedComp : LinkedComponents)
		{
			LinkedComp.RawPointInTimeAlpha = RawPointInTimeAlpha;
			LinkedComp.SetPointInTimeInternal(NewPointInTime);
		}

	}

	UFUNCTION()
	void StopAllConstants()
	{
		bAddConstantProgression = false;
		bAddConstantReverse = false;
	}

	UFUNCTION()
	void ActivatePassiveTarget()
	{		
		if (bCanBeTimeControlled)
			SetTimeWarpEffect(ETimeWarStencilState::Passive);

		// Update Links
		for (UTimeControlActorComponent LinkedComp : LinkedComponents)
		{
			LinkedComp.ActivatePassiveTarget();
		}
	}

	UFUNCTION()
	void ActivateTimeControl()
	{
		bIsCurrentlyBeingTimeControlled = true;
		SetTimeWarpEffect(ETimeWarStencilState::Active);

		// Update Links
		for (UTimeControlActorComponent LinkedComp : LinkedComponents)
		{
			LinkedComp.ActivateTimeControl();
		}

		// If we're set to force fully advance/reverse our 
		// constant progression we should set that now
		if (bForceFullyReverse && GetPointInTime() > 0.f && bAddConstantReverse && ConstantIncreaseValue > 0.f)
			ForcedPlayerAction = ETimeControlPlayerAction::ReverseTime;
		if (bForceFullyAdvance && GetPointInTime() < 1.f && bAddConstantProgression && ConstantIncreaseValue > 0.f)
			ForcedPlayerAction = ETimeControlPlayerAction::ProgressTime;
	}

	void DeactivateEffect()
	{
		if (bCanBeTimeControlled)
			SetTimeWarpEffect(ETimeWarStencilState::Idle);
		else
			SetTimeWarpEffect(ETimeWarStencilState::Nothing);
		
		for (UTimeControlActorComponent LinkedComp : LinkedComponents)
		{
			LinkedComp.DeactivateEffect();	
		}
	}

	void DeactivateAbility()
	{
		bIsCurrentlyBeingTimeControlled = false;
		ForcedPlayerAction = ETimeControlPlayerAction::Nothing;
		CodyStoppedInteractionEvent.Broadcast();

		if (bCanBeTimeControlled)
			SetTimeWarpEffect(ETimeWarStencilState::Idle);
		else
			SetTimeWarpEffect(ETimeWarStencilState::Nothing);

		if(LinkedMaster == nullptr)
		{
			ChangePlayerAction(ETimeControlPlayerAction::Nothing);

			// Update Links
			for (UTimeControlActorComponent LinkedComp : LinkedComponents)
			{
				LinkedComp.DeactivateAbility();
			}
		}
	}

	UFUNCTION()
	void ManuallySetPointInTime(float NewPointInTime)
	{
		if(LinkedMaster == nullptr && HasControl())
		{
			RawPointInTimeAlpha = FMath::Clamp(NewPointInTime, 0.f, 1.f);

			const float TimePosition = GetPointInTime();
			if (TimePosition == 0.f && !bHasBroadcastedDelegate)
			{
				BroadcastTimeTimeReached(TimePosition);
			}
			else if (TimePosition == 1.f && !bHasBroadcastedDelegate)
			{
				BroadcastTimeTimeReached(TimePosition);
			}
			SetPointInTimeInternal(TimePosition);
		}
	}
	
	void BroadcastTimeFullyReversedInternally()
	{
		TimeFullyReversedEvent.Broadcast();
		bHasBroadcastedDelegate = true;

		for (UTimeControlActorComponent LinkedComp : LinkedComponents)
		{
			LinkedComp.BroadcastTimeFullyReversedInternally();			
		}
	}

	void BroadcastTimeFullyProgressedInternally(bool bAlsoOnLinked = true)
	{
		TimeFullyProgressedEvent.Broadcast();
		bHasBroadcastedDelegate = true;

		for (UTimeControlActorComponent LinkedComp : LinkedComponents)
		{
			LinkedComp.BroadcastTimeFullyProgressedInternally();			
		}
	}

	UFUNCTION(NetFunction)
	void NetBroadcastTimeTimeReached(float Time)
	{
		BroadcastTimeTimeReached(Time);
	}

	void BroadcastTimeTimeReached(float Time)
	{
		if(LinkedMaster == nullptr)
		{
			if(Time >= 1.f)
			{
				BroadcastTimeFullyProgressedInternally();		
			}
			else if(Time <= 0.f)
			{
				BroadcastTimeFullyReversedInternally();
			}
		}
	}

	float EasePointInTime(ETimeControlActorEaseFunction Enum, float OldPointInTime)const
	{
		float NewPointInTime; 
		
		switch (Enum)
            {   
                case ETimeControlActorEaseFunction::CircularIn: 
					NewPointInTime = FMath::CircularIn(0.f, 1.f, OldPointInTime);
                break;
                
                case ETimeControlActorEaseFunction::CircularOut:
					NewPointInTime = FMath::CircularOut(0.f, 1.f, OldPointInTime);                    
                break;
                
                case ETimeControlActorEaseFunction::CircularInOut:
					NewPointInTime = FMath::CircularInOut(0.f, 1.f, OldPointInTime);
                break;

				case ETimeControlActorEaseFunction::ExpoIn:
					NewPointInTime = FMath::ExpoIn(0.f, 1.f, OldPointInTime);
                break;

				case ETimeControlActorEaseFunction::ExpoOut:
					NewPointInTime = FMath::ExpoOut(0.f, 1.f, OldPointInTime);
                break;

				case ETimeControlActorEaseFunction::ExpoInOut:
					NewPointInTime = FMath::ExpoInOut(0.f, 1.f, OldPointInTime);
                break;

				case ETimeControlActorEaseFunction::SinusoidalIn:
					NewPointInTime = FMath::SinusoidalIn(0.f, 1.f, OldPointInTime);
                break;

				case ETimeControlActorEaseFunction::SinussoidalOut:
					NewPointInTime = FMath::SinusoidalOut(0.f, 1.f, OldPointInTime);
                break;

				case ETimeControlActorEaseFunction::SinussoidalInOut:
					NewPointInTime = FMath::SinusoidalInOut(0.f, 1.f, OldPointInTime);	
                break;

				case ETimeControlActorEaseFunction::CustomCurve:
					if (EaseCustomCurve != nullptr)
						NewPointInTime = EaseCustomCurve.GetFloatValue(OldPointInTime);
					else
						NewPointInTime = OldPointInTime;
				break;
            } 

		 return NewPointInTime;
	}

	void FlipProgressDirection()
	{
		bool bReverse = bAddConstantProgression;
		bAddConstantProgression = !bReverse;
		bAddConstantReverse = bReverse;
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentProgressSpeedValue()
	{
		return CurrentProgressSpeed;
	}

	UFUNCTION(BlueprintPure)
	ETimeControlPlayerAction GetCurrentPlayerActionEnum()
	{
		return CurrentPlayerAction;
	}

	void SendPointInTimeCrumbs(float DeltaTime)
	{
		float CurrentSyncInterval = SyncTime;
		if (bIsCurrentlyBeingTimeControlled)
			CurrentSyncInterval = 0.05f;

		ETimeControlCrumbType CurrentDirection = ETimeControlCrumbType::Static;
		if (RawPointInTimeAlpha != ActiveCrumb.RawPointInTimeAlpha)
		{
			TotalStaticValueTimer = 0.f;
			bIsCrumbTrailSleeping = false;

			if (RawPointInTimeAlpha > ActiveCrumb.RawPointInTimeAlpha)
				CurrentDirection = ETimeControlCrumbType::Increasing;
			else
				CurrentDirection = ETimeControlCrumbType::Decreasing;
		}
		else if (!bIsCrumbTrailSleeping)
		{
			TotalStaticValueTimer += DeltaTime;
			if (TotalStaticValueTimer > 1.f && ActiveCrumb.CrumbType == ETimeControlCrumbType::Unknown && !bIsCurrentlyBeingTimeControlled)
			{
				NetSleepCrumbTrail();
				bIsCrumbTrailSleeping = true;
			}
		}

		if (bIsCrumbTrailSleeping)
			return;

		if (ActiveCrumb.CrumbType == ETimeControlCrumbType::Unknown)
			ActiveCrumb.CrumbType = CurrentDirection;
		PreviousCrumbDirection = CurrentDirection;

		if (CurrentDirection != ActiveCrumb.CrumbType
			|| bIsCurrentlyBeingTimeControlled != ActiveCrumb.bIsBeingTimeControlled)
		{
			if (ActiveCrumb.ControlDuration != 0.f)
				NetSendCrumb(ActiveCrumb);
			ActiveCrumb.ControlDuration = DeltaTime;
			ActiveCrumb.CrumbType = CurrentDirection;
			ActiveCrumb.RawPointInTimeAlpha = RawPointInTimeAlpha;
			ActiveCrumb.bIsBeingTimeControlled = bIsCurrentlyBeingTimeControlled;
		}
		else
		{
			ActiveCrumb.ControlDuration += DeltaTime;
			ActiveCrumb.RawPointInTimeAlpha = RawPointInTimeAlpha;

			if (ActiveCrumb.ControlDuration >= CurrentSyncInterval)
			{
				NetSendCrumb(ActiveCrumb);
				ActiveCrumb.ControlDuration = 0.f;
				ActiveCrumb.CrumbType = ETimeControlCrumbType::Unknown;
				ActiveCrumb.RawPointInTimeAlpha = RawPointInTimeAlpha;
				ActiveCrumb.bIsBeingTimeControlled = bIsCurrentlyBeingTimeControlled;
			}
		}
	}

	UFUNCTION(BlueprintPure)
	ETimeControlCrumbType GetSyncedNetworkTimeControlDirection()
	{
		if (LinkedMasterComp != nullptr)
			return LinkedMasterComp.GetSyncedNetworkTimeControlDirection();
		if (HasControl())
		{
			return PreviousCrumbDirection;
		}
		else
		{
			if (bIsFrozenInCrumbTrail)
				return ETimeControlCrumbType::Static;
			else
				return PreviousCrumbDirection;
		}
	}

	UFUNCTION(BlueprintPure)
	bool GetSyncedNetworkIsBeingTimeControlled()
	{
		if (LinkedMasterComp != nullptr)
			return LinkedMasterComp.GetSyncedNetworkIsBeingTimeControlled();
		if (HasControl())
		{
			return bIsCurrentlyBeingTimeControlled;
		}
		else
		{
			return bPreviousCrumbIsBeingControlled;
		}
	}

	UFUNCTION(NetFunction)
	private void NetSendCrumb(FTimeControlCrumb Crumb)
	{
		if (!HasControl())
		{
			bIsCrumbTrailSleeping = false;
			Crumbs.Add(Crumb);
		}
	}

	UFUNCTION(NetFunction)
	private void NetSleepCrumbTrail()
	{
		bIsCrumbTrailSleeping = true;
	}

	float GetTimeNeededToFinishCrumbTrail()
	{
		float TotalTime = 0.f;
		float PrevAlpha = RawPointInTimeAlpha;
		for (int i = 0, Count = Crumbs.Num(); i < Count; ++i)
		{
			if (Crumbs[i].CrumbType == ETimeControlCrumbType::Static
				|| bUseAcceleration || bUseDeceleration || ConstantIncreaseValue == 0.f)
			{
				TotalTime += Crumbs[i].ControlDuration;
			}
			else if (Crumbs[i].CrumbType == ETimeControlCrumbType::Wrapping)
			{
				continue;
			}
			else
			{
				float Speed = FMath::Abs(Crumbs[i].bIsBeingTimeControlled ? TimeStepMultiplier : ConstantIncreaseValue);
				if (Speed > 0.f)
					TotalTime += FMath::Abs(Crumbs[i].RawPointInTimeAlpha - PrevAlpha) / Speed;
				PrevAlpha = Crumbs[i].RawPointInTimeAlpha;
			}
		}
		return TotalTime;
	}

	void UpdatePointInTimeFromCrumbs(float DeltaTime)
	{
		float CurrentSyncInterval = SyncTime;
		if (bIsCurrentlyBeingTimeControlled)
			CurrentSyncInterval = 0.05f;

		if (bIsFrozenInCrumbTrail)
		{
			if (GetTimeNeededToFinishCrumbTrail() >= (CurrentSyncInterval * 2.f + DeltaTime) || bIsCrumbTrailSleeping)
			{
				bIsFrozenInCrumbTrail = false;
			}
			else
			{
				return;
			}
		}

		float TrailLength = GetTimeNeededToFinishCrumbTrail();
		if (TrailLength < DeltaTime && !bIsCrumbTrailSleeping)
		{
			bIsFrozenInCrumbTrail = true;
			return;
		}

		float ExcessTrail = FMath::Max((TrailLength - DeltaTime) - (CurrentSyncInterval * 3.f), 0.f);
		float RemainingDeltaTime = DeltaTime;
		while (Crumbs.Num() != 0 && RemainingDeltaTime > 0.f)
		{
			PreviousCrumbDirection = Crumbs[0].CrumbType;
			bPreviousCrumbIsBeingControlled = Crumbs[0].bIsBeingTimeControlled;

			if (Crumbs[0].CrumbType == ETimeControlCrumbType::Static)
			{
				if (ExcessTrail > 0.f)
					Crumbs[0].ConsumeDuration(ExcessTrail);
				Crumbs[0].ConsumeDuration(RemainingDeltaTime);

				if (Crumbs[0].ControlDuration <= 0.f)
					Crumbs.RemoveAt(0);

				// We can't go from static to non-static within the same frame
				if (Crumbs.Num() == 0 || Crumbs[0].CrumbType != ETimeControlCrumbType::Static)
					break;
			}
			else if (Crumbs[0].CrumbType == ETimeControlCrumbType::Wrapping)
			{
				RawPointInTimeAlpha = Crumbs[0].RawPointInTimeAlpha;
				Crumbs.RemoveAt(0);
			}
			else if (bUseAcceleration || bUseDeceleration || ConstantIncreaseValue == 0.f)
			{
				// If we are using acceleration or deceleration, we don't guarantee static speeds,
				// so follow the time that's in the crumb
				if (RemainingDeltaTime >= Crumbs[0].ControlDuration)
				{
					RemainingDeltaTime -= Crumbs[0].ControlDuration;
					RawPointInTimeAlpha = Crumbs[0].RawPointInTimeAlpha;
					Crumbs.RemoveAt(0);
				}
				else
				{
					float PreviousRawPointInTime = RawPointInTimeAlpha;
					RawPointInTimeAlpha = FMath::Lerp(
						RawPointInTimeAlpha,
						Crumbs[0].RawPointInTimeAlpha,
						(RemainingDeltaTime / Crumbs[0].ControlDuration));

					Crumbs[0].ControlDuration -= RemainingDeltaTime;
					RemainingDeltaTime = 0.f;
					break;
				}
			}
			else
			{
				// Without acceleration or deceleration, always use a static speed lerp
				// instead of using the control duration
				float AlphaDelta = Crumbs[0].RawPointInTimeAlpha - RawPointInTimeAlpha;
				float Speed = FMath::Abs(Crumbs[0].bIsBeingTimeControlled ? TimeStepMultiplier : ConstantIncreaseValue);

				float TimeToReach = Speed > 0.f ? FMath::Abs(AlphaDelta / Speed) : 0.f;
				if (TimeToReach > RemainingDeltaTime)
				{
					RawPointInTimeAlpha = FMath::FInterpConstantTo(
						RawPointInTimeAlpha,
						Crumbs[0].RawPointInTimeAlpha,
						RemainingDeltaTime, Speed);
					RemainingDeltaTime = 0.f;
					break;
				}
				else
				{
					RemainingDeltaTime -= TimeToReach;
					RawPointInTimeAlpha = Crumbs[0].RawPointInTimeAlpha;
					Crumbs.RemoveAt(0);
				}
			}
		}
	}

	UFUNCTION()
	void SendWrappingCrumb()
	{
		if (!HasControl())
			return;

		if (ActiveCrumb.ControlDuration > 0.f)
		{
			NetSendCrumb(ActiveCrumb);
			ActiveCrumb.ControlDuration = 0.f;
			ActiveCrumb.CrumbType = ETimeControlCrumbType::Unknown;
			ActiveCrumb.RawPointInTimeAlpha = RawPointInTimeAlpha;
			ActiveCrumb.bIsBeingTimeControlled = bIsCurrentlyBeingTimeControlled;
		}

		FTimeControlCrumb WrapCrumb;
		WrapCrumb.ControlDuration = 0.f;
		WrapCrumb.bIsBeingTimeControlled = bIsCurrentlyBeingTimeControlled;
		WrapCrumb.CrumbType = ETimeControlCrumbType::Wrapping;
		WrapCrumb.RawPointInTimeAlpha = RawPointInTimeAlpha;
		NetSendCrumb(WrapCrumb);
	}
}
