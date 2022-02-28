
// event void FBouncePerchGrabbed(AHazePlayerCharacter Player);

// class UBouncePerchComponent : UHazeActivationPoint
// {
// 	UPROPERTY()
// 	float PerPlayerCooldown = 4.f;

// 	UPROPERTY()
// 	FBouncePerchGrabbed OnPlayerBounced;

// 	private TPerPlayer<float> PreviousUseTime;

// 	UFUNCTION(BlueprintOverride)
// 	EHazeActivationPointStatusType CanBeGrabbedBy(AHazePlayerCharacter Player) const
// 	{
// 		float PrevTime = PreviousUseTime[Player];
// 		if (PrevTime == 0.f)
// 			return EHazeActivationPointStatusType::Grabable;
// 		return Time::GetGameTimeSince(PrevTime) > PerPlayerCooldown ? EHazeActivationPointStatusType::Grabable : EHazeActivationPointStatusType::NotGrabable;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnGrabbed(AHazePlayerCharacter Player)
// 	{
// 		PreviousUseTime[Player] = Time::GetGameTimeSeconds();
// 		OnPlayerBounced.Broadcast(Player);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void BeginPlay()
// 	{
// 		Capability::AddPlayerCapabilityRequest(n"BouncePerchCapability");
// 	}

// 	UFUNCTION(BlueprintOverride)
//     void EndPlay(EEndPlayReason Reason)
//     {
// 		Capability::RemovePlayerCapabilityRequest(n"BouncePerchCapability");
// 	}
// };