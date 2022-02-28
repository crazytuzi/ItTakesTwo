import Peanuts.Audio.AudioStatics;
import Vino.Audio.Footsteps.FootstepStatics;
import Vino.Audio.Movement.PlayerMovementAudioEventData;

class UAnimNotify_GroundPound : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "GroundPound";
	}
	
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		if (MeshComp.GetOwner() == nullptr)
			return true;


		auto HazeOwner = Cast<AHazeActor>(MeshComp.Owner);
		if (HazeOwner == nullptr)
			return true;

		AHazePlayerCharacter PlayerOwner = Cast<AHazePlayerCharacter>(HazeOwner);
		if (PlayerOwner == nullptr)
			return true;


		FFootstepTrace Trace;

		if (HazeOwner != nullptr)
		{			
			auto MoveComp = UHazeMovementComponent::Get(MeshComp.Owner);
			if (MoveComp != nullptr && !MoveComp.CanCalculateMovement())
			{
				// Extract what material we are standing on.
				GetFootstepTraceFromMovementComponent(MoveComp, Trace);
			}
			else
			{
				// We do not have any data on what we are standing on, trace to find out.
				FVector HipLoc = MeshComp.GetSocketLocation(n"Hips");
				// Extend from bounding box a bit to increase chans of hitting floor.
				float TraceDistance = MeshComp.BoundingBoxExtents.Z * 2.f;

				PerformFootstepTrace(
					HipLoc,
					HipLoc + HazeOwner.MovementWorldUp * -TraceDistance,
					Trace);
			}
		}
		
		if (Trace.PhysAudio != nullptr && PlayerOwner != nullptr)
		{
			auto PoundEffect = Trace.PhysAudio.GetGroundPoundEffectEvent();
			if(PoundEffect != nullptr)
			{
				Niagara::SpawnSystemAttached(PoundEffect, PlayerOwner.RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
			}
		}
		return true;
	}
}