import Cake.LevelSpecific.Music.LevelMechanics.Classic.FollowCloud.FollowCloudSettings;
import Cake.LevelSpecific.Music.LevelMechanics.Classic.FollowCloud.FollowCloudBoundsComponent;

class UFollowCloudOutOfBoundsCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"FollowCloudOutOfBounds");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;

	UFollowCloudSettings Settings;
	FVector Destination; 	
	UFollowCloudBoundsComponent Bounds = nullptr;
	float DoneEnteringTime = BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Settings = UFollowCloudSettings::GetSettings(Owner);
		Bounds = UFollowCloudBoundsComponent::Get(Owner);
		ensure(Bounds != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Bounds.IsWithinBounds(Owner.ActorLocation))
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Bounds.IsWithinBounds(Owner.ActorLocation) && (Time::GetGameTimeSeconds() > DoneEnteringTime))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Move to position within bounds (no need to replicate destination, as movement is replicated anyway)
		FVector CloudLoc = Owner.ActorLocation;
		Destination = Bounds.GetRandomLocationWithinBounds(Settings.ReturnWithinBoundsDepth);
		DoneEnteringTime = BIG_NUMBER;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector CloudLocation = Owner.GetActorLocation();
		if ((DoneEnteringTime == BIG_NUMBER) && Bounds.IsWithinBounds(Owner.ActorLocation))
		{
			DoneEnteringTime = Time::GetGameTimeSeconds() + Settings.ReturnWithinBoundsDuration;
		}

		if(!Destination.IsNear(CloudLocation, Settings.ReturnWithinBoundsDepth * 0.5f))
		{
			FVector ToDestination = (Destination - CloudLocation).GetSafeNormal();
			float ToDestSpeed = Owner.ActualVelocity.DotProduct(ToDestination);
			FVector2D SpeedRange = FVector2D(0.5f, 1.f) * Settings.ReturnMaxSpeed;
			float Force = FMath::GetMappedRangeValueClamped(SpeedRange, FVector2D(Settings.ReturnForce, 0.f), ToDestSpeed);
			FVector Impulse = ToDestination * Force;
			if (!Bounds.IsAbovePlane(CloudLocation))
				Impulse = Math::SlerpVectorTowards(Impulse, FVector::UpVector, Settings.ReturnFromBelowPlaneUpwardsBias);
			Owner.AddImpulse(Impulse);
		}
	}
}
