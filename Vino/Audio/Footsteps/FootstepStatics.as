import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;
import Vino.Movement.Components.MovementComponent;

struct FFootstepTrace
{
	bool bPerformed = false;
	bool bGrounded = false;
	UPhysicalMaterial PhysMaterial;
	UPhysicalMaterialAudio PhysAudio;
};

void GetFootstepTraceFromMovementComponent(UHazeMovementComponent MoveComp, FFootstepTrace& Trace)
{
	if (Trace.bPerformed)
		return;

	Trace.bPerformed = true;
	Trace.bGrounded = MoveComp.IsGrounded();

	Trace.PhysMaterial = MoveComp.ContactSurfaceMaterial;
	if (Trace.PhysMaterial != nullptr)
		Trace.PhysAudio = Cast<UPhysicalMaterialAudio>(Trace.PhysMaterial.AudioAsset);
}

void PerformFootstepTrace(FVector Start, FVector End, FFootstepTrace& Trace)
{
	if (Trace.bPerformed)
		return;
	Trace.bPerformed = true;

	FHazeHitResult Hit;

	FHazeTraceParams FloorTrace;
	FloorTrace.InitWithCollisionProfile(n"PlayerCharacter");
	FloorTrace.From = Start;
	FloorTrace.To = End;

	if (FloorTrace.Trace(Hit))
	{
		Trace.bGrounded = true;
		Trace.PhysMaterial = Audio::GetPhysMaterialFromHit(Hit.FHitResult, FloorTrace);
		if (Trace.PhysMaterial != nullptr)
			Trace.PhysAudio = Cast<UPhysicalMaterialAudio>(Trace.PhysMaterial.AudioAsset);
	}
	else
	{
		Trace.bGrounded = false;
	}
};
