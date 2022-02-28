import Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollowerComponent;
import Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollower;

class UMusicalFollowerLocationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityDebugCategory = n"LevelSpecific";
	
	UMusicalFollowerComponent FollowerComp;
	UHazeMovementComponent MoveComp;

	bool bCloseToGround = false;

	bool bWasHittingGround = false;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		FollowerComp = UMusicalFollowerComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if(FollowerComp.Followers.Num() == 0)
		{
			return EHazeNetworkActivation::DontActivate;
		}
		
		if(!Owner.IsAnyCapabilityActive(n"MusicalFlying") && !Owner.IsAnyCapabilityActive(n"MusicalHover"))
		{
			return EHazeNetworkActivation::DontActivate;
		}
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(IsFollowerCloseToGround())
		{
			SetLeaderFollowerBehindPlayer();
			bWasHittingGround = true;
		}
		else
		{
			SetLeaderFollowerBelowPlayer();
			bWasHittingGround = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetLeaderFollowerBehindPlayer();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(FollowerComp.Followers.Num() == 0)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}
		
		if(!Owner.IsAnyCapabilityActive(n"MusicalFlying") && !Owner.IsAnyCapabilityActive(n"MusicalHover"))
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const bool bHitGround = IsFollowerCloseToGround();

		if(bHitGround && !bWasHittingGround)
		{
			SetLeaderFollowerBehindPlayer();
		}
		else if(!bHitGround && bWasHittingGround)
		{
			SetLeaderFollowerBelowPlayer();
		}

		bWasHittingGround = bHitGround;
	}

	void SetLeaderFollowerBelowPlayer()
	{
		AMusicalFollower Follower = GetLeaderFollower();

		if(Follower == nullptr)
		{
			return;
		}

		Follower.SteeringBehavior.Follow.LocalOffset = FollowerComp.FlyingTargetOffset;
	}

	void SetLeaderFollowerBehindPlayer()
	{
		AMusicalFollower Follower = GetLeaderFollower();

		if(Follower == nullptr)
		{
			return;
		}

		Follower.SteeringBehavior.Follow.LocalOffset = FollowerComp.GroundedTargetOffset;
	}

	AMusicalFollower GetLeaderFollower() const
	{
		return FollowerComp.Followers.Num() > 0 ? FollowerComp.Followers[0] : nullptr;
	}

	bool IsFollowerCloseToGround(float DebugDraw = -1.0f) const
	{
		FHitResult Hit;
		const bool bHitGround = MoveComp.LineTraceGround(Owner.ActorLocation, Hit, 1000.0f, DebugDraw);
		return bHitGround;
	}
}