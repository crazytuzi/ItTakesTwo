import Vino.Movement.Swinging.SwingSettings;
import Vino.Movement.Components.MovementComponent;
import Vino.ActivationPoint.ActivationPointStatics;

event void FOnSwingPointAttached(AHazePlayerCharacter Player);
event void FOnSwingPointDetached(AHazePlayerCharacter Player);
event void FOnSwingPointEnableChange();

// Default swingcomponent what you swing on
class USwingPointComponent : UHazeActivationPoint
{	
	default ValidationIdentifier = EHazeActivationPointIdentifierType::Movement;
	default PrimaryComponentTick.bStartWithTickEnabled = true;
	default bShowWidgetInFullScreen = true;
	default EvaluationInterval = EHazeActivationPointTickIntervalType::EveryThirdFrame;

	UPROPERTY(Category = "Attribute")
	bool bEnabled = true;

	UPROPERTY(Category = "Attribute")
	float RopeLength = 900.f;
	UPROPERTY(Category = "Attribute")
	float SwingAngle = 70.f;
	
	UPROPERTY(Category = "Attribute")
	FSwingSpeedSettings SpeedSettings;

	UPROPERTY(Category = "Attribute")
	FSwingAttachSettings AttachSettings;

	UPROPERTY(Category = "Attribute")
	FSwingDetachSettings DetachSettings;
	default DetachSettings.Jump.MinSpeed = 1800.f;
	default DetachSettings.Jump.MaxSpeed = 2000.f;
	default DetachSettings.Jump.MinAngle = 40.f;
	default DetachSettings.Jump.MaxAngle = 50.f;

	default DetachSettings.Cancel.MinSpeed = 0.f;
	default DetachSettings.Cancel.MaxSpeed = 1000.f;
	default DetachSettings.Cancel.MinAngle = -90.f;
	default DetachSettings.Cancel.MaxAngle = 90.f;

	UPROPERTY(Category = "Attribute")
	FSwingCameraSettings CameraSettings;

	UPROPERTY(Category = "Attribute")
	bool bInheritRotation = false;

	UPROPERTY(Category = "Attribute")
	bool bShowRopeKnotMesh = true;

	TPerPlayer<float> PlayerDetachTime;

	/*
		!! LEGACY !!
		You will get more control using the new detach settings!

		What percentage of your exit velocity is clamped (1) and how much is your natural swing velocity (0)
	*/
	UPROPERTY(Category = "Attribute")
	float JumpFixedVelocityScale = 1.f;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettingsOverride;

	default WidgetClass = Asset("/Game/Blueprints/Movement/Swinging/WBP_SwingingWidget.WBP_SwingingWidget_C");

	default InitializeDistance(EHazeActivationPointDistanceType::Visible, 3500.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 2500.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 1300.f);	
	default ValidationIdentifier = EHazeActivationPointIdentifierType::Movement;

	UPROPERTY()
	FOnSwingPointAttached OnSwingPointAttached;
	UPROPERTY()
	FOnSwingPointDetached OnSwingPointDetached;

	UPROPERTY()
	FOnSwingPointEnableChange OnSwingPointEnabled;
	UPROPERTY()
	FOnSwingPointEnableChange OnSwingPointDisabled;

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		OnSwingPointEnabled.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		OnSwingPointDisabled.Broadcast();
		
		// Always disable
		return false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{	
		if (!bEnabled)
			return EHazeActivationPointStatusType::Invalid;

		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);

		FVector SwingToPlayer = Player.CapsuleComponent.WorldLocation - WorldLocation;
		float RelativeHeightDot = MoveComp.WorldUp.DotProduct(SwingToPlayer);
		if (MoveComp.IsGrounded() && RelativeHeightDot > 0.f)
			return EHazeActivationPointStatusType::Invalid;

		/*
			Add a cooldown to the swing point.
			If the swing point is behind the player, give it a longer cooldown
		*/
		const float SwingPointDirectionDot = (-SwingToPlayer).DotProduct(Player.ViewRotation.ForwardVector);
		const float TimeSinceLastDetach = System::GetGameTimeInSeconds() - PlayerDetachTime[Player];
		const float Cooldown = SwingPointDirectionDot >= 0.f ? AttachSettings.CooldownInFront : AttachSettings.CooldownBehind;
		if (TimeSinceLastDetach < Cooldown)
			return EHazeActivationPointStatusType::Invalid;		

		EHazeActivationAsyncStatusType TraceStatus = CanPlayerReachActivationPoint(Player, MoveComp, Query);

		if(TraceStatus == EHazeActivationAsyncStatusType::NoData)
			return EHazeActivationPointStatusType::Invalid;
		
		if(TraceStatus == EHazeActivationAsyncStatusType::TraceFoundCollision)
			return EHazeActivationPointStatusType::Invalid;

		return EHazeActivationPointStatusType::Valid;
	}

	// EXAMPLE HOW TO USE THE GetSortedIndexAmongValidQuerries
	// UFUNCTION(BlueprintOverride)
	// EHazeActivationPointStatusType SetupWidgetVisibility(AHazePlayerCharacter Player, FHazeQueriedActivationPointWithWidgetInformation Query) const
	// {	
	// 	int SortedIndex = -1;
	// 	int Count = -1;
	// 	Query.GetSortedIndexAmongValidQuerries(Player, SortedIndex, Count);
	// 	PrintToScreen("" + Owner.GetName() + " Index: " + SortedIndex + " Count: " + Count);
	// 	return EHazeActivationPointStatusType::Valid;
	// }

	EHazeActivationAsyncStatusType CanPlayerReachActivationPoint(AHazePlayerCharacter Player, UHazeMovementComponent MoveComp, FHazeQueriedActivationPoint& QueryPoint) const
	{
		FHazeTraceParams Settings;
		Settings.InitWithMovementComponent(MoveComp);
		Settings.UnmarkToTraceWithOriginOffset();
		Settings.SetToLineTrace();

		// Setup Ignores
		AActor PointOwner = QueryPoint.Point.GetOwner();
		Settings.IgnoreActor(PointOwner);
		
		// Ignore attach parent if specified
		AActor PointAttachParent = PointOwner.GetAttachParentActor();
		if (PointAttachParent != nullptr)
			Settings.IgnoreActor(PointAttachParent);

		UHazeActivationPoint ActivePoint = Player.GetActivePoint();
		if (ActivePoint != nullptr)
			Settings.IgnoreActor(ActivePoint.GetOwner());

		// Setup From To
		Settings.From = Player.GetActorCenterLocation();
		Settings.MakeFromRelative(Player.RootComponent);
		Settings.To = QueryPoint.Transform.GetLocation();
		Settings.MakeToRelative(QueryPoint.GetPoint());

		// Make the trace
		FHitResult HitResult;
		return QueryPoint.AsyncTrace(Player, Settings, HitResult);
	}

	UFUNCTION(BlueprintOverride)
	float SetupValidationScoreAlpha(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query, float CompareDistanceAlpha) const
	{	
		const float ScoreAlpha = ActivationPointsStatics::CalculateValidationScoreAlpha(Player, Query, CompareDistanceAlpha);
		return ScoreAlpha;
	}	

	FVector GetClosestPointOnSwingSphere(FVector WorldLoc)
	{
		FVector SwingPointToWorldLocation = WorldLoc - GetWorldLocation();
		SwingPointToWorldLocation.Normalize();
		SwingPointToWorldLocation *= RopeLength;	

		return GetWorldLocation() + SwingPointToWorldLocation;
	}

	UFUNCTION()
	void SetSwingPointEnabled(bool bNewEnabled = false)
	{
		if (!HasControl())
			return;
			
		NetSwingPointEnabled(bNewEnabled);
	}

	UFUNCTION(NetFunction)
	void NetSwingPointEnabled(bool bNewEnabled)
	{
		MakeAvailable(bNewEnabled);
		bEnabled = bNewEnabled;
	}
}
