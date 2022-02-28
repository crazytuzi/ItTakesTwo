enum EPointOfInterestMarkerWidgetVisType
{
	Hidden,
	VisibleOnlyOffScreen,
	VisibleOnlyOnScreen,
	Visible
};

class UPointOfInterestMarkerWidget : UHazeUserWidget
{

	UPROPERTY()
	EPointOfInterestMarkerWidgetVisType VisiblityType;

	UPROPERTY()
	UMaterialInstance IconMaterialInstance;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool bDesignTime)
	{
		SetMarkerMaterial(IconMaterialInstance);
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void SetMarkerVisibility(EPointOfInterestMarkerWidgetVisType VisType)
	{

	}

	UFUNCTION(BlueprintEvent)
	void SetMarkerSize(int MarkerSize)
	{

	}

	UFUNCTION(BlueprintEvent)
	void SetMarkerMaterial(UMaterialInstance Material)
	{
		
	}
}

class UMarkerIconWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	float LerpVisibility = 0.f;

	UPROPERTY(NotEditable)
	UWidget ImageWidget;

	UPointOfInterestMarkerWidget ParentMarker;
	float PrevVisibility = 1.f;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		ParentMarker = Cast<UPointOfInterestMarkerWidget>(GetParentWidgetOfClass(UPointOfInterestMarkerWidget::StaticClass()));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float DeltaTime)
	{
		// Update visibility lerp
		if (ParentMarker.VisiblityType == EPointOfInterestMarkerWidgetVisType::VisibleOnlyOffScreen)
			LerpVisibility = FMath::FInterpTo(LerpVisibility, ParentMarker.bIsOnEdgeOfScreen ? 1.f : 0.f, DeltaTime, 10.f);
		else if (ParentMarker.VisiblityType == EPointOfInterestMarkerWidgetVisType::VisibleOnlyOnScreen)
			LerpVisibility = FMath::FInterpTo(LerpVisibility, ParentMarker.bIsOnEdgeOfScreen ? 0.f : 1.f, DeltaTime, 10.f);
		else if (ParentMarker.VisiblityType == EPointOfInterestMarkerWidgetVisType::Visible)
			LerpVisibility = FMath::FInterpTo(LerpVisibility, 1.f, DeltaTime, 10.f);
		else
			LerpVisibility = FMath::FInterpTo(LerpVisibility, 0.f, DeltaTime, 10.f);

		// Set new state on widget
		if (PrevVisibility != 0.f || LerpVisibility != 0.f)
		{
			float CameraDot = ParentMarker.DotInFrontOfCamera;
			float Scale = FMath::Lerp(0.7f, 1.f, Math::Saturate(CameraDot)) * FMath::Lerp(0.1f, 1.f, LerpVisibility);
			ImageWidget.SetRenderScale(FVector2D(Scale, Scale));

			float Opacity = LerpVisibility * FMath::Lerp(0.1f, 1.f, Math::Saturate((CameraDot + 1.f) * 0.5f));
			ImageWidget.SetRenderOpacity(Opacity);

			PrevVisibility = LerpVisibility;
		}
	}
};