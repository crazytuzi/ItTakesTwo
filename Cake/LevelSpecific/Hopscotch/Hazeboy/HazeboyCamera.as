class UHazeboyCameraAnimComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UCurveFloat Curve;

	UPROPERTY(EditInstanceOnly, Category = "Animation")
	AActor TargetRoot;

	float Time = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Time += DeltaTime;
		float Alpha = Curve.GetFloatValue(Time);

		FTransform ParentTransform = AttachParent.WorldTransform;
		FVector RelativeTarget = ParentTransform.InverseTransformPosition(TargetRoot.ActorLocation);

		RelativeLocation = RelativeTarget * Alpha;

		// Hard coded in the cameras pitch *shrug emoji*
		RelativeRotation = FRotator(-75.f * Alpha, 0.f, 0.f);

		float MinTime = 0.f, MaxTime = 0.f;
		Curve.GetTimeRange(MinTime, MaxTime);
	}

	void PlayAnimation()
	{
		Time = 0.f;
		SetComponentTickEnabled(true);

		FTransform ParentTransform = AttachParent.WorldTransform;
		FVector RelativeTarget = ParentTransform.InverseTransformPosition(TargetRoot.ActorLocation);

		RelativeLocation = RelativeTarget;
		RelativeRotation = FRotator(-90.f, 0.f, 0.f);
	}
}

class UHazeboyCamera : USceneCaptureComponent2D
{
	default PrimitiveRenderMode = ESceneCapturePrimitiveRenderMode::PRM_UseShowOnlyList;

	UPROPERTY(Category = "Widgets")
	float WidgetResolution = 120;

	UPROPERTY(Category = "Widgets")
	UMaterialInterface WidgetMaterial;

	TMap<UUserWidget, UWidgetComponent> WidgetCompMap;
	AActor WidgetDummyActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WidgetDummyActor = SpawnActor(AActor::StaticClass(), Level = Owner.GetLevel());
		WidgetDummyActor.AttachToComponent(this);
#if EDITOR
		WidgetDummyActor.ActorLabel = "HazeboyWidgetActor";
#endif

		ShowOnlyActors.Add(WidgetDummyActor);
	}

	UUserWidget AddWidget(TSubclassOf<UUserWidget> WidgetClass, float Distance)
	{
		auto Widget = Widget::CreateUserWidget(nullptr, WidgetClass);

		auto WidgetComp = UWidgetComponent::Create(WidgetDummyActor);
		WidgetComp.AttachToComponent(this);
		WidgetComp.SetWidget(Widget);
		WidgetComp.SetMaterial(0, WidgetMaterial);
		WidgetComp.DrawSize = FVector2D(WidgetResolution, WidgetResolution);

		// Move it and point it towards the camera!
		FTransform WidgetTransform;
		WidgetTransform.Location = FVector::ForwardVector * Distance;
		WidgetTransform.Rotation = Math::MakeQuatFromX(-FVector::ForwardVector);

		// Size is trickier... we need to calculate the frustrum size.
		float HalfFov = FMath::DegreesToRadians(FOVAngle / 2.f);
		float HalfFrustrumHeight = FMath::Tan(HalfFov) * Distance;

		WidgetTransform.Scale3D = FVector((HalfFrustrumHeight * 2.f) / WidgetResolution);
		WidgetComp.RelativeTransform = WidgetTransform;

		WidgetCompMap.Add(Widget, WidgetComp);

		return Widget;
	}

	void RemoveWidget(UUserWidget Widget)
	{
		auto Comp = WidgetCompMap[Widget];
		Comp.DestroyComponent(Comp);

		WidgetCompMap.Remove(Widget);
	}
}