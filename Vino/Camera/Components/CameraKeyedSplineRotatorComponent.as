import Vino.Camera.Components.CameraSplineFollowerComponent;

struct FKeyedCamera
{
	UPROPERTY()
	UHazeCameraComponent Camera;
	UPROPERTY()
	float DistanceAlongSpline;

	FRotator GetRotation() const property
	{
		if (!ensure(Camera != nullptr))
			return FRotator::ZeroRotator;

		return Camera.WorldRotation;
	}

	FQuat GetQuat() const property
	{
		if (!ensure(Camera != nullptr))
			return FQuat::Identity;

		return FQuat(Camera.WorldRotation);
	}
}

event void FOnDuplicateCamera(const FVector& Location, const FRotator& Rotation);

FKeyedCamera GetKeyedCameraSnappedToSpline(UHazeCameraComponent Camera, UHazeSplineComponentBase Spline)
{
	FKeyedCamera KeyedCamera;
	KeyedCamera.Camera = Camera;
	KeyedCamera.DistanceAlongSpline = Spline.GetDistanceAlongSplineAtWorldLocation(Camera.WorldLocation);

	return KeyedCamera;
}

UCLASS(HideCategories="Activation Physics LOD AssetUserData Collision Rendering Cooking")
class UCameraKeyedSplineRotatorComponent : UHazeCameraParentComponent
{
	UPROPERTY()
	UHazeSplineComponentBase KeyedSpline = nullptr;

	UPROPERTY()
	TArray<FKeyedCamera> KeyedCameras;

	// How fast we move along the spline  
	UPROPERTY()
	float FollowSpeed = 1.f;

	// The camera is offset this many units behind the follow target along the camera spline.
	UPROPERTY()
	float BackwardsOffset = 0.f;

	// How do we choose which location we should follow?
	UPROPERTY()
	ESplineFollowType FollowType = ESplineFollowType::Weighted;

	// If true, we will follow dead players the same as alive ones. If false, we will only follow dead players if both players are dead.
	UPROPERTY()
	bool bAlwaysFollowDeadPlayers = false;
	bool bFollowBothPlayers = false;

	// Follow target for the player activating this camera
	UPROPERTY()
	FSplineFollowTarget UserFollowTarget;
	default UserFollowTarget.Weight = 1.f;

	// Follow target for the player not activating this camera
	UPROPERTY()
	FSplineFollowTarget OtherPlayerFollowTarget;

	// Additional follow targets
	UPROPERTY()
	TArray<FSplineFollowTarget> FollowTargets;

	FHazeAcceleratedFloat DistanceAlongSpline;
	AHazePlayerCharacter PlayerUser = nullptr;
	TArray<FSplineFollowTarget> AllFollowTargets; // Includes player follow targets

	UFUNCTION(BlueprintOverride)
	void EditorPostDuplicate()
	{
		// KeyedCameras will belong to the original, we'll have to place new ones manually (doing it in construction script is bug prone.)
		KeyedCameras.Empty();
	}

	void CleanKeyedCameras()
	{
		for (int j = KeyedCameras.Num() - 1; j >= 0; j--)
		{
			// Clear out any removed cameras...
			if (KeyedCameras[j].Camera == nullptr)
				KeyedCameras.RemoveAt(j);	
			// ...cameras without owner...		
			else if (KeyedCameras[j].Camera.Owner == nullptr)	
				KeyedCameras.RemoveAt(j);
			else if (KeyedCameras[j].Camera.Owner != Owner)
			{
				// ...and cameras whose owners are attached to another actor (we can get this when duplicating camera actors).
				AActor OtherParent = KeyedCameras[j].Camera.Owner.AttachParentActor;
				if ((OtherParent != nullptr) && (OtherParent != Owner))
					KeyedCameras.RemoveAt(j);
			}		
		}
	}

	UFUNCTION()
	void AddKeyedCamera(FKeyedCamera KeyedCamera)
	{
		CleanKeyedCameras();

		// Sort new one into list
		int i = 0;
		for (; i < KeyedCameras.Num(); i++)
		{
			if (KeyedCameras[i].DistanceAlongSpline > KeyedCamera.DistanceAlongSpline)
				break;
		}
		KeyedCameras.Insert(KeyedCamera, i);
	}

	void ReplaceKeyedCamera(FKeyedCamera KeyedCamera)
	{	
		if (KeyedCamera.Camera == nullptr)
			return;

		for (int i = 0; i < KeyedCameras.Num(); i++)
		{
			if (KeyedCameras[i].Camera == KeyedCamera.Camera)
			{
				KeyedCameras.RemoveAt(i);
				break;
			}			
		}

		AddKeyedCamera(KeyedCamera);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent User, EHazeCameraState PreviousState)
	{
		// Add user and other player follow targets if appropriate.
		PlayerUser = Cast<AHazePlayerCharacter>(User.GetOwner());
		UserFollowTarget.Target.Actor = User.GetOwner();
		OtherPlayerFollowTarget.Target.Actor = (PlayerUser != nullptr) ? PlayerUser.GetOtherPlayer() : nullptr;

		InitializeFollowTargets(FollowTargets, UserFollowTarget, OtherPlayerFollowTarget, AllFollowTargets, bFollowBothPlayers);

		if (PreviousState == EHazeCameraState::Inactive)
		{
			// Camera was not previously blending out or active
			Snap();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraFinishedBlendingOut(UHazeCameraUserComponent User, EHazeCameraState PreviousState)
	{
		AllFollowTargets = FollowTargets;
	}

    UFUNCTION(BlueprintOverride)
    void Snap()
	{
		if ((Camera == nullptr) || (Camera.GetUser() == nullptr) || (KeyedSpline == nullptr))
			return;

		DistanceAlongSpline.Value = GetTargetDistanceAlongSpline(Camera.GetUser());
		DistanceAlongSpline.Velocity = 0.f;
		Update(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void Update(float DeltaSeconds)
	{
		if ((Camera == nullptr) || (Camera.GetUser() == nullptr) || (KeyedSpline == nullptr) || (KeyedCameras.Num() == 0))
			return;

		float SplineLength = KeyedSpline.GetSplineLength();		
		float TargetDistAlongSpline = GetTargetDistanceAlongSpline(Camera.GetUser());
		if (KeyedSpline.IsClosedLoop() && (FMath::Abs(TargetDistAlongSpline - DistanceAlongSpline.Value) > SplineLength * 0.5f))
		{
			// Looping past start/end if shorter than the other way around
			if (DistanceAlongSpline.Value > SplineLength * 0.5f)
				TargetDistAlongSpline += SplineLength;
			else
				TargetDistAlongSpline -= SplineLength;
		}
		if (FollowSpeed > 0.f)
		 	DistanceAlongSpline.AccelerateTo(TargetDistAlongSpline, 1.f / FollowSpeed, DeltaSeconds);  

		// In case of looping spline, we might need to mod the result
		if (DistanceAlongSpline.Value < 0.f)
			DistanceAlongSpline.Value += SplineLength;
		if (DistanceAlongSpline.Value > SplineLength)
			DistanceAlongSpline.Value -= SplineLength;		

		SetWorldRotation(GetTargetRotation(DistanceAlongSpline.Value));
	}

	FRotator GetTargetRotation(float DistanceAlongSpline)
	{
		for (int i = 0; i < KeyedCameras.Num(); i++)
		{
			if (KeyedCameras[i].DistanceAlongSpline > DistanceAlongSpline)
			{
				if (i == 0)
					return KeyedCameras[0].Rotation;

				float StartDistance = KeyedCameras[i - 1].DistanceAlongSpline;
				float EndDistance = KeyedCameras[i].DistanceAlongSpline;

				float Alpha = (DistanceAlongSpline - StartDistance) / (EndDistance - StartDistance);
				return FQuat::Slerp(KeyedCameras[i - 1].Quat, KeyedCameras[i].Quat, Alpha).Rotator();
			}
		}

		if (KeyedCameras.Num() > 0)
			return KeyedCameras.Last().Rotation;
		return WorldRotation;
	}

	
	float GetTargetDistanceAlongSpline(UHazeCameraUserComponent User)
	{
		if (KeyedSpline == nullptr)
			return 0.f;

		if (User.GetOwner() == nullptr)
			return 0.f;

		float Fraction = GetFollowFraction();
		float TargetDistance = Fraction * KeyedSpline.GetSplineLength();
		TargetDistance -= BackwardsOffset;
		if (!KeyedSpline.IsClosedLoop())
			TargetDistance = FMath::Clamp(TargetDistance, 0.f, KeyedSpline.GetSplineLength());
		return TargetDistance;
	}

	float GetFollowFraction()
	{
		// If both players are dead, we allow them as focus targets
		bool bFollowDeadPlayers = bAlwaysFollowDeadPlayers || !bFollowBothPlayers || AreBothPlayersDead();
		switch (FollowType)
		{
			case ESplineFollowType::Foremost:
				return GetForemostFollowFraction(bFollowDeadPlayers);
			case ESplineFollowType::Rearmost:
				return GetRearmostFollowFraction(bFollowDeadPlayers);
		} 
		// case ESplineFollowType::Weighted:
		return GetWeightedFollowFraction(bFollowDeadPlayers);
	}

	float GetWeightedFollowFraction(bool bFollowDeadPlayers)
	{
		FVector LocationSum = FVector::ZeroVector;
		float WeightSum = 0.f;
		for (FSplineFollowTarget FollowTarget : AllFollowTargets)
		{
			if (!FollowTarget.IsValid(bFollowDeadPlayers))
				continue;
			FVector FolloweeLoc = FollowTarget.Target.GetFocusLocation(PlayerUser);
			LocationSum += FolloweeLoc * FollowTarget.Weight;
			WeightSum += FollowTarget.Weight;

			// if (bDebugDraw) 
			// 	System::DrawDebugLine(FolloweeLoc, FolloweeLoc + FVector(0,0, FollowTarget.Weight * 100), FLinearColor::Yellow, 0, 3);
		}

		if (WeightSum == 0.f)
			return 0.f;

		// if (bDebugDraw) 
		// 	System::DrawDebugLine(LocationSum / WeightSum, LocationSum / WeightSum + FVector(0,0, WeightSum * 100), FLinearColor::Green, 0, 5);

		return KeyedSpline.FindFractionClosestToWorldLocation(LocationSum / WeightSum);
	}

	float GetForemostFollowFraction(bool bFollowDeadPlayers)
	{
		float ForemostFraction = 0.f;
		for (FSplineFollowTarget FollowTarget : AllFollowTargets)
		{
			if (!FollowTarget.IsValid(bFollowDeadPlayers))
				continue;
			FVector FolloweeLoc = FollowTarget.Target.GetFocusLocation(PlayerUser);
			float Fraction = KeyedSpline.FindFractionClosestToWorldLocation(FolloweeLoc);
			if (Fraction > ForemostFraction)
				ForemostFraction = Fraction;
		}

		// if (bDebugDraw)
		// 	DebugDrawPositionalFollowTargets(ForemostFraction);

		return ForemostFraction;
	}

	float GetRearmostFollowFraction(bool bFollowDeadPlayers)
	{
		float RearmostFraction = 1.f;
		for (FSplineFollowTarget FollowTarget : AllFollowTargets)
		{
			if (!FollowTarget.IsValid(bFollowDeadPlayers))
				continue;
			FVector FolloweeLoc = FollowTarget.Target.GetFocusLocation(PlayerUser);
			float Fraction = KeyedSpline.FindFractionClosestToWorldLocation(FolloweeLoc);
			if (Fraction < RearmostFraction)
				RearmostFraction = Fraction;
		}

		// if (bDebugDraw)
		// 	DebugDrawPositionalFollowTargets(RearmostFraction);
	
		return RearmostFraction;
	}
}

