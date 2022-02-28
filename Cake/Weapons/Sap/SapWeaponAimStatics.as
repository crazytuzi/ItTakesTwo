import Vino.Trajectory.TrajectoryStatics;
import Cake.Weapons.Sap.SapWeaponSettings;
import Cake.Weapons.Sap.SapAttachTarget;
import Cake.Weapons.Sap.SapResponseComponent;
import Peanuts.Aiming.AutoAimStatics;
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

const FStatID STAT_SapQueryRay(n"SapQueryRay");
const FStatID STAT_SapQueryRayComplex(n"SapQueryRayComplex");

FSapAttachTarget SelectBestAttachTarget(FSapAttachTarget First, FSapAttachTarget Second, FVector Origin, FVector Direction)
{
	if (!First.IsValid())
		return Second;
	if (!Second.IsValid())
		return First;

	// If they're both auto aim, or _none_ of them are auto-aim, choose the closest one
	if (First.bIsAutoAim == Second.bIsAutoAim)
	{
		float FirstDist = Direction.DotProduct(First.WorldLocation - Origin);
		float SecondDist = Direction.DotProduct(Second.WorldLocation - Origin);

		if (FirstDist > SecondDist)
			return Second;
		else
			return First;
	}

	// Otherwise, choose the one that is autoaim
	return First.bIsAutoAim ? First : Second;
}

FSapAttachTarget SapQueryAimTarget(AHazePlayerCharacter Player, FVector Origin, FVector Direction)
{
	FSapAttachTarget AutoAimTarget;
	FSapAttachTarget RayTraceTarget;

	// Check auto aiming
	FAutoAimLine AutoAim = GetAutoAimForTargetLine(Player, Origin, Direction, Sap::Aim::MinTraceDistance, Sap::Aim::MaxTraceDistance, true);
	if (AutoAim.bWasAimChanged)
	{
		AutoAimTarget.Component = AutoAim.AutoAimedAtComponent;
		AutoAimTarget.RelativeLocation = FVector::ZeroVector;
		AutoAimTarget.bIsAutoAim = true;
	}

	// Check line trace!
	RayTraceTarget = SapQueryRay(
		Origin + Direction * Sap::Aim::MinTraceDistance,
		Origin + Direction * Sap::Aim::MaxTraceDistance,
		Sap::Aim::SwarmSearchRadius,
		false
	);

	// Select the best one :)
	FSapAttachTarget Result = SelectBestAttachTarget(AutoAimTarget, RayTraceTarget, Origin, Direction);

	// This is kind of hard-codey, but for auto aimed stuff, just point the normal straight towards the origin
	if (Result.bIsAutoAim)
		Result.WorldNormal = -Direction;

	return Result;
}

FSapAttachTarget SapQueryRay(FVector RayStart, FVector RayEnd, float RayWidth, bool bQueryComplex)
{
#if TEST
	FScopeCycleCounter EntryCounter(STAT_SapQueryRay);
#endif

	FSapAttachTarget Result;
	Result.RelativeLocation = RayEnd;
	Result.RelativeNormal = (RayStart - RayEnd).GetSafeNormal();

	TArray<FHitResult> Hits;
	// Make spheretrace
	System::LineTraceMulti(
		RayStart, RayEnd, ETraceTypeQuery::SapTrace,
		false, TArray<AActor>(), EDrawDebugTrace::None, Hits, true);

	for(auto Hit : Hits)
	{
		if (SapQueryHit(Hit, RayWidth, bQueryComplex, Result))
			break;
	}

	return Result;
}

bool SapQueryHit(FHitResult Hit, float RayWidth, bool bQueryComplex, FSapAttachTarget& AttachTarget)
{
	// Check for swarm hits!
	if (Cast<ASwarmActor>(Hit.Actor) != nullptr)
	{
		ASwarmActor Swarm = Cast<ASwarmActor>(Hit.Actor);

		FName SwarmBone;
		float ParticleDistance = 0.f;
		FVector RayPosition;
		USwarmSkeletalMeshComponent SwarmSkelMeshComp = nullptr;
		const bool bFoundParticle = Swarm.FindParticleClosestToRay(Hit.TraceStart, Hit.TraceEnd, SwarmSkelMeshComp, SwarmBone, RayPosition, ParticleDistance);

		if(bFoundParticle)
		{
			FVector BoneLoc = SwarmSkelMeshComp.GetSocketLocation(SwarmBone);
			FTransform BoneTransform = SwarmSkelMeshComp.GetSocketTransform(SwarmBone);

			if (ParticleDistance < RayWidth)
			{
				// The particle is close enough!
				AttachTarget.RelativeLocation = FVector::ZeroVector;
				AttachTarget.RelativeNormal = FVector::ZeroVector;
				AttachTarget.Component = SwarmSkelMeshComp;
				AttachTarget.Socket = SwarmBone;
				AttachTarget.bIsAutoAim = true;
				AttachTarget.WorldOffset = FVector::ZeroVector;
				return true;
			}

		}

	}

	// Blocking hit, check if we're also hitting something complex....
	if (Hit.bBlockingHit)
	{
		if (bQueryComplex)
		{
#if TEST
			FScopeCycleCounter EntryCounter(STAT_SapQueryRayComplex);
#endif

			FHitResult ComplexHit;
			FVector HitLocation;
			FVector HitNormal;
			FName HitSocket;

			bool bHasHit = Hit.Component.LineTraceComponent(Hit.TraceStart, Hit.TraceEnd, true, false, false, HitLocation, HitNormal, HitSocket, ComplexHit);
			ComplexHit.SetBlockingHit(bHasHit);

			if (ComplexHit.bBlockingHit)
			{
				AttachTarget.SetFromHit(ComplexHit);
				return true;
			}
		}
		else
		{
			AttachTarget.SetFromHit(Hit);
			return true;
		}
	}

	return false;
}

FVector CalculateSapExitVelocity(FVector MuzzleLocation, FSapAttachTarget Target)
{
	// Sap response components might override how high the saps should lob, for faster projectile speed
	if (Target.Actor != nullptr)
	{
		auto ResponseComp = USapResponseComponent::Get(Target.Actor);
		if (ResponseComp != nullptr && ResponseComp.bOverrideSapSpeed)
		{
			return CalculateVelocityForPathWithHorizontalSpeed(
				MuzzleLocation, Target.WorldLocation,
				Sap::Projectile::Gravity, ResponseComp.CustomSapSpeed);
		}
	}

	return CalculateVelocityForPathWithHeight(
		MuzzleLocation, Target.WorldLocation,
		Sap::Projectile::Gravity, Sap::Shooting::Lobbing);
}