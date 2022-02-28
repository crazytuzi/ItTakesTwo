import Cake.Environment.HazeSphere;
import Peanuts.Spline.SplineActor;

// @todo: Sampling a spline only places the spline in the correct position, should also place the root object
// at the position of sampled root in order to place spawned components correctly.

class ASplineComponentActor : ASplineActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent HazeDefaultSceneRoot;
	default HazeDefaultSceneRoot.Mobility = EComponentMobility::Static;

	// The number of components to spawn along the curve in ConstructionScript,
	UPROPERTY(Category="Spline Component Actor", meta = (ClampMin = "2", UIMin = "2"))
	int NumberOfComponents;
	default NumberOfComponents = 2;

	// Allow for copying of other splines in the world,
	UPROPERTY(Category="Spline Component Actor")
	AActor Sample;

	USceneComponent GetComponentTemplate() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// If we're sampling another curve, copy it's spline to this
		if (Sample != nullptr)
		{
			UHazeSplineComponent Other = Cast<UHazeSplineComponent>(Sample.GetComponentByClass(UHazeSplineComponent::StaticClass()));
			if (Other != nullptr)
			{
				Spline.CopyFromOtherSpline(Other);
			}
		}

		FTransform TemplateTransform = FTransform();
		USceneComponent Template = GetComponentTemplate();
		if (Template != nullptr)
		{
			TemplateTransform = Template.RelativeTransform;
		}

		// Solve the transform for each actor component to be spawned.
		TArray<FTransform> Transforms = Spline.TransformsAlongSpline(NumberOfComponents);
		for (FTransform Transform : Transforms)
		{
			// Create the Actor Component and cast it to a scene component to be able to set it's relative transform,
			USceneComponent Component = Cast<USceneComponent>(Editor::CreateComponentFromTemplate(this, ComponentTemplate, FName()));
			if (Component != nullptr)
			{
				Component.SetHiddenInGame(false);
				Component.bIsEditorOnly = true;
				FTransform ComponentTransform = FTransform(
					Transform.Rotation,
					Transform.Translation + TemplateTransform.Translation,					
					TemplateTransform.Scale3D
				);

				Component.SetRelativeTransform(ComponentTransform);
			}
		}
	}	
}

class ASplinePointLightActor : ASplineComponentActor
{
	
	UPROPERTY(DefaultComponent)
	UPointLightComponent PointLightTemplate;
	default PointLightTemplate.bIsEditorOnly = true;

	USceneComponent GetComponentTemplate() override
	{
		return PointLightTemplate;
	}
}

class ASplineHazeSphereActor : ASplineComponentActor
{
	UPROPERTY(DefaultComponent)
	UHazeSphereComponent HazeSphereTemplate;
	default HazeSphereTemplate.bIsEditorOnly = true;

	USceneComponent GetComponentTemplate() override
	{
		return HazeSphereTemplate;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		HazeSphereTemplate.ConstructionScript_Hack();
		Super::ConstructionScript();
	}
}

class ASplineStaticMeshActor : ASplineComponentActor
{
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.bIsEditorOnly = true;

	USceneComponent GetComponentTemplate() override
	{
		return Mesh;
	}
}

class ASplineNiagaraSystemActor : ASplineComponentActor
{
	UPROPERTY(DefaultComponent)
	UNiagaraComponent NiagaraTemplate;
	default NiagaraTemplate.bIsEditorOnly = true;

	USceneComponent GetComponentTemplate() override
	{
		return NiagaraTemplate;
	}
}

// @todo: Implement the drawing of the reflection capture influence area.
class ASplineSphereReflectionCaptureActor : ASplineComponentActor
{
	UPROPERTY(DefaultComponent)
	USphereReflectionCaptureComponent CaptureComponentTemplate;
	default CaptureComponentTemplate.bIsEditorOnly = true;

	USceneComponent GetComponentTemplate() override
	{
		return CaptureComponentTemplate;
	}

	// void CreatePreviewShapes()
	// {
	// 	float InfluenceRadius = CaptureComponentTemplate.InfluenceRadius;
	// 	// float CaptureRadius = CaptureComponentTemplate.Radius;
	// 	TArray<UActorComponent> Components = GetComponentsByClass(USphereReflectionCaptureComponent::StaticClass());
	// 	for (UActorComponent Component : Components)
	// 	{
	// 		// Cast the given actor component to the correct class,
	// 		USphereReflectionCaptureComponent CaptureComponent = Cast<USphereReflectionCaptureComponent>(Component);
			
	// 		// Create the draw sphere,
	// 		UDrawSphereComponent DrawSphere = Cast<UDrawSphereComponent>(CreateComponent(UDrawSphereComponent::StaticClass(), FName("")));
	// 		DrawSphere.AttachToComponent(CaptureComponent);
	// 		DrawSphere.SetSphereRadius(InfluenceRadius);
	// 		CaptureComponent.PreviewInfluenceRadius = DrawSphere; // Requires USphereReflectionCaptureComponent.PreviewInfluenceRadius to be exposed,

	// 		// @todo: Seems the ASphereReflectionCapture actor holds the BillboardComponent and DrawCaptureRadius*
	// 		// not sure if we're missing out on anything important from not having them apart from visualization
	// 		// for art.
	// 	}
	// }
	
	// UFUNCTION(BlueprintOverride)
	// void ConstructionScript()
	// {
	// 	Super::ConstructionScript();
	// 	CreatePreviewShapes();
	// }
}

class ASplineBoxReflectionCaptureActor : ASplineComponentActor
{
	UPROPERTY(DefaultComponent)
	UBoxReflectionCaptureComponent CaptureComponentTemplate;
	default CaptureComponentTemplate.bIsEditorOnly = true;

	// void CreatePreviewShapes()
	// {
	// 	float InfluenceRadius = CaptureComponentTemplate.;
	// 	TArray<UActorComponent> Components = GetComponentsByClass(USphereReflectionCaptureComponent::StaticClass());
	// 	for (UActorComponent Component : Components)
	// 	{
	// 		// Cast the given actor component to the correct class,
	// 		USphereReflectionCaptureComponent CaptureComponent = Cast<USphereReflectionCaptureComponent>(Component);
			
	// 		// Create the draw sphere,
	// 		UDrawSphereComponent DrawSphere = Cast<UDrawSphereComponent>(CreateComponent(UDrawSphereComponent::StaticClass(), FName("")));
	// 		DrawSphere.AttachToComponent(CaptureComponent);
	// 		DrawSphere.SetSphereRadius(InfluenceRadius);
	// 		CaptureComponent.PreviewInfluenceRadius = DrawSphere;

	// 		CaptureComponent.SetbVisualizeComponent(true);

	// 		// @todo: Seems the ASphereReflectionCapture actor holds the BillboardComponent and DrawCaptureRadius*
	// 		// not sure if we're missing out on anything important from not having them apart from visualization
	// 		// for art.
	// 	}
	// }

	USceneComponent GetComponentTemplate() override
	{
		return CaptureComponentTemplate;
	}
}