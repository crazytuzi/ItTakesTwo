import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerRespawnComponent;
import Vino.Checkpoints.Volumes.DeathVolume;

/* Anywhere this volume is placed the player will not be able to respawn-in-place at. */
class ADisallowRespawnInPlaceVolume : AVolume
{
    default Shape::SetVolumeBrushColor(this, FLinearColor::Purple);
};

bool PrepareRespawnInPlace(AHazePlayerCharacter Player, FPlayerRespawnEvent& OutEvent)
{
	UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player);
	UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player);
	UHazeBaseMovementComponent MoveComp = UHazeBaseMovementComponent::Get(Player);

	if (!HealthComp.DoDeathEffectsSupportRespawnInPlace())
		return false;

	OutEvent.LocationRelativeTo = Player.RootComponent;
	OutEvent.RelativeLocation = FVector::ZeroVector;
	OutEvent.Rotation = Player.ActorRotation;
	OutEvent.RespawnEffect = RespawnComp.RespawnInPlaceEffect;
	return true;
}

/*bool UNUSED_PerpareRespawnAtDeathLocation(AHazePlayerCharacter Player, FPlayerRespawnEvent& OutEvent)
{
	UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player);
	UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player);
	UHazeBaseMovementComponent MoveComp = UHazeBaseMovementComponent::Get(Player);

	if (!HealthComp.DiedAtLocation.bValid)
		return false;
	if (!HealthComp.DoDeathEffectsSupportRespawnInPlace())
		return false;

	UPrimitiveComponent RelativeComp = HealthComp.DiedAtLocation.RelativeToComponent;
	FVector RelativeLocation = HealthComp.DiedAtLocation.Location;

	FVector WorldLocation = RelativeLocation;
	if (RelativeComp != nullptr)
		WorldLocation = RelativeComp.WorldTransform.TransformPositionNoScale(RelativeLocation);

	// Make sure we will be grounded within a reasonable distance
	// after we respawn.
	FVector LineStart = WorldLocation;
	FVector LineEnd = WorldLocation + (MoveComp.WorldUp * -500.f);

	FHitResult DownHit;
	TArray<AActor> ActorsToIgnore;
	System::LineTraceSingleByProfile(
		LineStart, LineEnd,
		n"PlayerCharacter", false,
		ActorsToIgnore, EDrawDebugTrace::None,
		DownHit, false);

	if (DownHit.bBlockingHit)
	{
		// Set the new world location to be just above the ground
		WorldLocation = DownHit.ImpactPoint + (MoveComp.WorldUp * 5.f);

		// Make it relative to the ground if we can
		RelativeComp = DownHit.Component;
		RelativeLocation = DownHit.Component.WorldTransform.InverseTransformPositionNoScale(WorldLocation);
	}
	else
	{
		// We couldn't find the ground, don't allow respawn in place
		return false;
	}

	TArray<UPrimitiveComponent> Overlaps;
	Trace::CapsuleOverlapComponents(
		WorldLocation + (HealthComp.DiedAtLocation.Rotation.UpVector * Player.CapsuleComponent.CapsuleHalfHeight),
		HealthComp.DiedAtLocation.Rotation,
		Player.CapsuleComponent.CapsuleRadius,
		Player.CapsuleComponent.CapsuleHalfHeight,
		n"PlayerCharacter",
		Overlaps
	);

	for (UPrimitiveComponent Overlap : Overlaps)
	{
		// Ignore the player itself
		if (Overlap.Owner == Player)
			continue;

		// If the location we want to respawn at blocks respawn in place,
		// don't respawn and go to a normal checkpoint respawn instead.
		if (Cast<ADisallowRespawnInPlaceVolume>(Overlap.Owner) != nullptr)
			return false;

		// If the location we want to respawn at is inside a death volume,
		// don't respawn and go to a normal checkpoint respawn instead.
		if (Cast<ADeathVolume>(Overlap.Owner) != nullptr)
			return false;

		// Check that the location we're respawning into isn't obstructed by
		// anything at the moment. This can happen just during regular gameplay,
		// and we want to fall back to a checkpoint in that case.
		if (Overlap.GetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter) == ECollisionResponse::ECR_Block)
			return false;
	}

	// Yay, we can respawn in place!
	OutEvent.LocationRelativeTo = RelativeComp;
	OutEvent.RelativeLocation = RelativeLocation;
	OutEvent.Rotation = HealthComp.DiedAtLocation.Rotation;
	OutEvent.RespawnEffect = RespawnComp.RespawnInPlaceEffect;
	return true;
}*/