import Vino.Movement.Helpers.BurstForceStatics;
import Cake.LevelSpecific.Music.LevelMechanics.Classic.FollowCloud.FollowCloudSettings;
import Vino.Movement.MovementSettings;
import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;

class UFollowCloudPushAwayPlayersCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Push");
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default TickGroup = ECapabilityTickGroups::GamePlay;

	UCapsuleComponent Capsule;
	UFollowCloudSettings Settings;
	float ActivationRadius = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Capsule = UCapsuleComponent::Get(Owner);
		Settings = UFollowCloudSettings::GetSettings(Owner);
		ensure((Settings != nullptr) && (Capsule != nullptr));

		// Only activate when players are proximate
		ActivationRadius = (Capsule.CapsuleRadius + Capsule.CapsuleHalfHeight) * 2.f;  
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Game::Cody.ActorLocation.IsNear(Capsule.WorldLocation, ActivationRadius) && 
			!Game::May.ActorLocation.IsNear(Capsule.WorldLocation, ActivationRadius))
			return EHazeNetworkActivation::DontActivate;

		// Running locally, pushing only affects player flying movement which is crumbed. 
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TArray<AHazePlayerCharacter> Pushees = Game::GetPlayers();
		for (AHazePlayerCharacter Pushee : Pushees)
		{
			UMusicalFlyingComponent FlyingComp = UMusicalFlyingComponent::Get(Pushee);			
			if (FlyingComp == nullptr)
				continue;

			// Project target location to capsule center line
			FVector PushVelocity = FVector::ZeroVector;
			FVector PusheeLoc = Pushee.ActorLocation;
			FVector UpDir = Capsule.WorldTransform.Rotation.UpVector;
			FVector HalfCylinder = UpDir * (Capsule.CapsuleHalfHeight - Capsule.CapsuleRadius);
			FVector ProjectedLoc = Capsule.WorldLocation;
			float Dummy = 0.f; 
			Math::ProjectPointOnLineSegment(Capsule.WorldLocation + HalfCylinder, Capsule.WorldLocation - HalfCylinder, PusheeLoc, ProjectedLoc, Dummy);
			FVector FromCloud = PusheeLoc - ProjectedLoc;
			if (!FromCloud.IsNearlyZero() && (FromCloud.SizeSquared() < FMath::Square(Capsule.CapsuleRadius + Settings.PushPlayersCollisionPadding)))
			{
				float Dist = FromCloud.Size();
				FVector PusheeVel = Pushee.ActorVelocity;
				PushVelocity = FromCloud / Dist;
				PushVelocity *= Settings.PushPlayersForce;
				PushVelocity *= FMath::GetMappedRangeValueClamped(FVector2D(0.f, FMath::Square(Settings.PushPlayersCollisionPadding)), FVector2D(1.f, 0.f), FMath::Square(FMath::Max(Dist - Capsule.CapsuleRadius, 0.f)));			
				FlyingComp.FlyingImpulse = PushVelocity;// * DeltaTime;
			}
		}
	}
}
