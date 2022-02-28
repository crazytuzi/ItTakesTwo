import Peanuts.Spline.SplineActor;
import Vino.Movement.Grinding.GrindSpline;
import Peanuts.Spline.SplineMesh;
import Rice.Props.PropBaseActor;

UCLASS(Abstract)
class ASplineFollowerActor : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	UStaticMeshComponent RootComp;
	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bDisabledAtStart = false;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SceneComp;
	UPROPERTY()
	AGrindspline GrindSplineToFollow;
	UPROPERTY()
	APropBaseActor PropSplineToFollow;
	UPROPERTY()
	AActor SMNoteRollmesh;

	UPROPERTY()
	float DesiredFollowSpeed = 850.f;
	UPROPERTY()
	float CurrentFollowSpeed = 100;
	UPROPERTY()
	float LerpSpeed = 1.f;
	UPROPERTY()
	float RotationMultiplier = 1.f;
	UPROPERTY()
	bool bFollowingSpline = false;
	float DistanceAlongSpline = 0.f;

	float YScaleTarget = 0.1f;
	float ZScaleTarget = 0.1f;
	float CurrentYScale = 1;
	float CurrentZScale = 1;
	float fInterpFloatRoll;

	float CurrentSMOffset = 70;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SMNoteRollmesh.AttachToComponent(SceneComp, AttachmentRule = EAttachmentRule::SnapToTarget);
		SMNoteRollmesh.AddActorLocalOffset(FVector(0,0,CurrentSMOffset));

		if(GrindSplineToFollow != nullptr)
		{
			FVector Loc = GrindSplineToFollow.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
			FRotator Rot = GrindSplineToFollow.Spline.GetRotationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
			SetActorLocationAndRotation(Loc, Rot);
		}

		if(PropSplineToFollow != nullptr)
		{
			FVector Loc = PropSplineToFollow.BPSplineMeshGetSpline().GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
			FRotator Rot = PropSplineToFollow.BPSplineMeshGetSpline().GetRotationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
			SetActorLocationAndRotation(Loc, Rot);
		}
	}

	UFUNCTION()
	void StartFollowingSpline()
	{
		if(this.HasControl())
		{
			NetStartFollowingSpline();
		}
	}
	UFUNCTION(NetFunction)
	void NetStartFollowingSpline()
	{
		if(GrindSplineToFollow != nullptr)
		{
			bFollowingSpline = true;
		}
		if(PropSplineToFollow != nullptr)
		{
			bFollowingSpline = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bFollowingSpline)
		{

			CurrentFollowSpeed = FMath::FInterpTo(CurrentFollowSpeed, DesiredFollowSpeed, DeltaTime, LerpSpeed);
			DistanceAlongSpline += CurrentFollowSpeed * DeltaTime;

			if(GrindSplineToFollow != nullptr)
			{
				FVector Loc = GrindSplineToFollow.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
				FRotator Rot = GrindSplineToFollow.Spline.GetRotationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
				SetActorLocationAndRotation(Loc, Rot);
			}
			if(PropSplineToFollow != nullptr)
			{
				FVector Loc = PropSplineToFollow.BPSplineMeshGetSpline().GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
				FRotator Rot = PropSplineToFollow.BPSplineMeshGetSpline().GetRotationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
				SetActorLocationAndRotation(Loc, Rot);
			}

			FRotator RelativeRotation;
			RelativeRotation.Roll = FMath::Sin(Time::GameTimeSeconds * 3.f) * 3.f;
			fInterpFloatRoll = FMath::FInterpTo(fInterpFloatRoll, RelativeRotation.Roll, DeltaTime, 1.f);
			SceneComp.SetRelativeRotation(FRotator(fInterpFloatRoll, 90, 0));

			SMNoteRollmesh.AddActorLocalRotation(FRotator(0, 0, -15 * RotationMultiplier));
			CurrentYScale = FMath::Lerp(CurrentYScale, YScaleTarget, DeltaTime * 0.35f);
			CurrentZScale = FMath::Lerp(CurrentZScale, ZScaleTarget, DeltaTime * 0.35f);		
			SMNoteRollmesh.SetActorRelativeScale3D(FVector(SMNoteRollmesh.GetActorScale3D().X, CurrentYScale, CurrentZScale));

			CurrentSMOffset = FMath::Lerp(CurrentSMOffset, 15.f, DeltaTime * 0.35f);
			SMNoteRollmesh.SetActorRelativeLocation(FVector(0,0, CurrentSMOffset), false, FHitResult(), true);

			


			if(GrindSplineToFollow != nullptr)
			{
				if(DistanceAlongSpline >= GrindSplineToFollow.Spline.GetSplineLength())
				{
					bFollowingSpline = false;
					SMNoteRollmesh.SetActorHiddenInGame(true);
					SMNoteRollmesh.SetActorEnableCollision(false);
					SetActorEnableCollision(false);
					DisableActor(nullptr);
				}
			}

			if(PropSplineToFollow != nullptr)
			{
				if(DistanceAlongSpline >= PropSplineToFollow.BPSplineMeshGetSpline().GetSplineLength())
				{
					bFollowingSpline = false;
					SMNoteRollmesh.SetActorHiddenInGame(true);
					SetActorEnableCollision(false);
					DisableActor(nullptr);
				}
			}
		}
	}
	UFUNCTION()
	void ManuallyDisableActor()
	{
		if(this.HasControl())
		{
			NetManuallyDisableActor();
		}
	}
	UFUNCTION(NetFunction)
	void NetManuallyDisableActor()
	{
		SMNoteRollmesh.SetActorHiddenInGame(true);
		SetActorEnableCollision(false);
		DisableActor(nullptr);
	}
}