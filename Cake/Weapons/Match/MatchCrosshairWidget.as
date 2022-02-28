
struct FMatchAmmoWidgetData
{
	UPROPERTY()
	FVector2D OffsetFromCenter = FVector2D::ZeroVector;

	UPROPERTY()
	FHazeAcceleratedFloat DesiredScale;

	UPROPERTY()
	FHazeAcceleratedFloat DesiredAlpha;

	UPROPERTY()
	float Angle = 0.f;
}

import Cake.Weapons.Match.MatchWielderComponent;
class UMatchCrosshairWidget : UHazeUserWidget
{
	UPROPERTY(Category = "MatchWidget | Defaults")
	const float ArrowOffsetDistance_MAX = 26.f;

	UPROPERTY(Category = "MatchWidget | Defaults")
	const float ArrowOffsetDistance_MIN = 20.f;

	UPROPERTY(Category = "MatchWidget | Runtime", Transient, NotEditable)
	TArray<FMatchAmmoWidgetData> AmmoWidgetData;
	default AmmoWidgetData.SetNum(3);

	UPROPERTY(Category = "MatchWidget | Runtime", Transient, NotEditable)
	FVector AimWorldLocationCurrent;

	UPROPERTY(Category = "MatchWidget | Runtime", Transient, NotEditable)
	FVector AimWorldLocationDesired;

	UPROPERTY(Category = "MatchWidget | Runtime", Transient, NotEditable)
	bool bIsAutoAimed = false;

	UPROPERTY(Category = "MatchWidget | Runtime", Transient, NotEditable)
	float ArrowOffsetFromCenter = ArrowOffsetDistance_MIN;

	UPROPERTY(Category = "MatchWidget | Runtime", Transient, NotEditable)
	FVector2D Center_ScreenSpace= FVector2D::ZeroVector;

	UPROPERTY(Category = "MatchWidget | Runtime", Transient, NotEditable)
	FVector2D Center_PixelSpace = FVector2D::ZeroVector;

	const float ArrowAngleStepSize = TAU / 3.f;
	const float BaseCylinderRotation = PI * 0.5f * 3.f;
	const float PI_Half = 0.5f * PI;
	const float PI_OneThird = (1.f / 3.f) * PI;
	const float PI_TwoThirds = (2.f / 3.f) * PI;
	const float PI_OneFourth = (1.f / 4.f) * PI;
	const float OneAmmoRotation = PI_TwoThirds;

	FHazeAcceleratedFloat DynCylinderRot;
	float DynCylinderRotStiffness;
	float DynCylinderRotDamping;
	float DynCylinderRotDesiredAlpha;

	float ChargesPrev = 3.f;
	float ChargesFlooredPrev = 3.f;
	float ChargeState = 0.f;
	float CylinderRotation = 0.f;

	UMatchWielderComponent WielderComp;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		WielderComp = UMatchWielderComponent::GetOrCreate(Game::GetMay());
		UpdateDynCylinderRotation(0.f);
		DynCylinderRot.SnapTo(DynCylinderRotDesiredAlpha);
		ArrowOffsetFromCenter = ArrowOffsetDistance_MIN;
	}

	// // TEMP for debug purpose
	// float Charges = 3.f;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry& Geom, float DeltaTime)
	{
		CylinderRotation = BaseCylinderRotation;
		CylinderRotation += OneAmmoRotation;
		UpdateDynCylinderRotation(DeltaTime);
		CylinderRotation += (OneAmmoRotation * DynCylinderRot.Value);

		for(int i=0; i<3; ++i)
			UpdateAmmoWidgetData(i, DeltaTime);
	}

	UFUNCTION(BlueprintCallable, Category = "Match Widget")
	void DrawArrowHead(
		FPaintContext& Context,
		const FVector2D& InPixelSpacePos,
		const float InAngle,
		const FLinearColor InLinearColor,
		const float InThickness,
		const float InLength = 8.f
	) const
	{
		const float AngleA = InAngle + PI_OneFourth;
		const float AngleB = InAngle - PI_OneFourth;

		// The minus infront of the FMath::Cos() is needed when the 'Cylinder' is rotating counter-clockwise 
		const FVector2D LineA = InPixelSpacePos + FVector2D(-FMath::Cos(AngleA), FMath::Sin(AngleA)) * InLength;
		const FVector2D LineB = InPixelSpacePos + FVector2D(-FMath::Cos(AngleB), FMath::Sin(AngleB)) * InLength;

		WidgetBlueprint::DrawLine(Context, InPixelSpacePos, LineA, InLinearColor, true, InThickness);
		WidgetBlueprint::DrawLine(Context, InPixelSpacePos, LineB, InLinearColor, true, InThickness);
	}

	void UpdateAmmoWidgetData(float ArrowIdx, const float Dt)
	{
		const float Charges = WielderComp.Charges;

		float ArrowIdxPlusOne = ArrowIdx + 1.f;

		float DesiredAlpha = 0.f;
		if(Charges >= ArrowIdxPlusOne)
			DesiredAlpha = 1.0f;
		else if(FMath::IsWithinInclusive(Charges, ArrowIdx, ArrowIdxPlusOne))
			DesiredAlpha = 1.f + Charges - ArrowIdxPlusOne;

		AmmoWidgetData[ArrowIdx].DesiredAlpha.SpringTo(DesiredAlpha, 500.f, 1.f, Dt);
		const float DesiredAlphaSpeed  = AmmoWidgetData[ArrowIdx].DesiredAlpha.Velocity; 

		const float ArrowScale = AmmoWidgetData[ArrowIdx].DesiredScale.Value; 
		const float ArrowScaleSpeed  = AmmoWidgetData[ArrowIdx].DesiredScale.Velocity; 
		if(DesiredAlpha == 1.f && DesiredAlphaSpeed != 0.f && ArrowScale <= DesiredAlpha && ArrowScaleSpeed != 0.f)
		{
			AmmoWidgetData[ArrowIdx].DesiredAlpha.SnapTo(1.f);
			const float ExpansionSize = 1.5f;
			AmmoWidgetData[ArrowIdx].DesiredScale.SnapTo(ExpansionSize, AmmoWidgetData[ArrowIdx].DesiredScale.Velocity);
		}
		else if (DesiredAlpha == 1.f && ArrowScale == 0.f && ArrowScaleSpeed == 0.f)
		{
			AmmoWidgetData[ArrowIdx].DesiredAlpha.SnapTo(DesiredAlpha);
			AmmoWidgetData[ArrowIdx].DesiredScale.SnapTo(DesiredAlpha);
		}
		else if (DesiredAlpha == 1.f && ArrowScale != DesiredAlpha)
		{
			AmmoWidgetData[ArrowIdx].DesiredScale.AccelerateTo(1.f, 1.0f, Dt);
		}
		else
		{
			const float MinScale = 0.5f;
			const float TargetScaleValue = FMath::Lerp(MinScale, 1.f, DesiredAlpha); 
			AmmoWidgetData[ArrowIdx].DesiredScale.SpringTo(TargetScaleValue, 500.f, 1.f, Dt);
		}

		const float Angle = CylinderRotation + ArrowAngleStepSize * ArrowIdx; 

		float WidgetAngle = -Angle;

		// Due to how the image is rotated...
		WidgetAngle += PI_Half; 

		AmmoWidgetData[ArrowIdx].Angle = WidgetAngle;

		AmmoWidgetData[ArrowIdx].OffsetFromCenter = FVector2D(-FMath::Cos(Angle), FMath::Sin(Angle)); 
		AmmoWidgetData[ArrowIdx].OffsetFromCenter *= ArrowOffsetFromCenter; 
		// AmmoWidgetData[ArrowIdx].OffsetFromCenter /= GetCachedGeometry().GetLocalSize();
	}

	// World to may's viewport space
	FVector2D WorldToPixel(FVector InWorld) const
	{
		FVector2D Screen;
		SceneView::ProjectWorldToViewpointRelativePosition(Game::GetMay(), InWorld, Screen);
		FGeometry Geometry = GetCachedGeometry();
		return Screen * Geometry.GetLocalSize();
	}

	void UpdateDynCylinderRotation(const float DeltaTime )
	{
		const float Charges = WielderComp.Charges;
		const float ChargesFloored = FMath::FloorToFloat(Charges); 
		const float Fraction = Charges - ChargesFloored;

		if(ChargesFloored > ChargesFlooredPrev)
		{
			DynCylinderRotDamping = 0.6f;
			DynCylinderRotStiffness = 500.f;
			DynCylinderRotDesiredAlpha = 3.f - ChargesFloored;
		}
		else if(ChargesFloored < ChargesFlooredPrev)
		{
			if(ChargesFloored == 0.f)
			{
				DynCylinderRotDamping = 0.2f;
				DynCylinderRotStiffness = 1000.f;
			}
			else
			{
				DynCylinderRotDamping = 0.6f;
				DynCylinderRotStiffness = 1500.f;
			}
			DynCylinderRotDesiredAlpha = 3.f - ChargesFloored;
		}

		ChargesPrev = Charges;
		ChargesFlooredPrev = ChargesFloored;

		DynCylinderRot.SpringTo(
			DynCylinderRotDesiredAlpha,
			DynCylinderRotStiffness,
			DynCylinderRotDamping,
			DeltaTime
		);
	}

}

