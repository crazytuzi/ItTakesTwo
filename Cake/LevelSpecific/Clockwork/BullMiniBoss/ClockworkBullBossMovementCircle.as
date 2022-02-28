import Peanuts.Spline.SplineComponent;
import Peanuts.Spline.SplineActor;

class UClockworkBullBossMovementCircleStaticMeshComponent : UStaticMeshComponent
{
	default SetStaticMesh(Asset("/Game/Editor/Interaction/EditorGizmos_Interactpoint"));
    default SetHiddenInGame(true);
    default SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default SetRelativeScale3D(10.f);
	default bIsEditorOnly = true;
}

UCLASS()
class AClockworkBullBossMovementCircle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent ReqularChargeFromPosition;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent PillarHasFallenChargeFromPosition;

	UPROPERTY(EditInstanceOnly)
	ASplineActor ReqularSpline;

	UPROPERTY(EditInstanceOnly)
	ASplineActor PillarHasFallenSpline;

	private ASplineActor CurrentSpline;
	private USceneComponent CurrentChargeFromPosition;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
	#if EDITOR
        CreatePreviewComponents(ReqularChargeFromPosition);
		CreatePreviewComponents(PillarHasFallenChargeFromPosition);
	#endif
    }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		SetRegularMovementCircle();
		SetRegularChargeFromPosition();
	}

    void CreatePreviewComponents(USceneComponent AttachToComponent)
    {
        // Add an editor mesh for the actual point in the interaction
        UClockworkBullBossMovementCircleStaticMeshComponent PointMesh = UClockworkBullBossMovementCircleStaticMeshComponent::Create(this);
       		PointMesh.AttachToComponent(AttachToComponent);
    }

	UFUNCTION()
	void SetRegularMovementCircle()
	{
		CurrentSpline = ReqularSpline;
	}

	UFUNCTION()
	void SetPillarHasFallenMovementCircle()
	{
		CurrentSpline = PillarHasFallenSpline;
	}

	UFUNCTION()
	void SetRegularChargeFromPosition()
	{
		CurrentChargeFromPosition = ReqularChargeFromPosition;
	}

	UFUNCTION()
	void SetPillarHasFallenChargeFromPosition()
	{
		CurrentChargeFromPosition = PillarHasFallenChargeFromPosition;
	}
	
	USceneComponent GetChargeFromPosition() const property
	{
		return CurrentChargeFromPosition;
	}

	UHazeSplineComponent GetSpline()const property
	{
		return CurrentSpline.Spline;
	}
}