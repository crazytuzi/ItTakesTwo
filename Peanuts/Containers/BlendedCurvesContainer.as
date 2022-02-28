struct FBlendedCurve
{
	FHazeAcceleratedFloat Weight;
	UCurveFloat Curve;
	FRuntimeFloatCurve RuntimeCurve;
	bool bIsRuntimeFloatCurve = false;

	FBlendedCurve(UCurveFloat InCurve, float InWeight)
	{
		Curve = InCurve;
		Weight.SnapTo(InWeight);
		bIsRuntimeFloatCurve = false;
	}

	FBlendedCurve(FRuntimeFloatCurve InRuntimeCurve, float InWeight)
	{
		RuntimeCurve = InRuntimeCurve;
		Weight.SnapTo(InWeight);
		bIsRuntimeFloatCurve = true;
	}
}

struct FBlendedCurvesContainer
{
	float DefaultValue = 0.f;
	TArray<FBlendedCurve> Curves;
	float BlendDuration = 2.f;

	void SetTargetCurve(UCurveFloat Curve, float InBlendDuration)
	{
		if (InBlendDuration == 0.f)
		{
			// Snap target curve
			Curves.SetNum(1);
			Curves[0] = FBlendedCurve(Curve, 1.f);
			return;
		}

		BlendDuration = InBlendDuration;
		if ((Curves.Num() > 0) && (Curves.Last().Curve == Curve) && !Curves.Last().bIsRuntimeFloatCurve)
			return; // Already current
		
		if (Curves.Num() == 0)
		{
			// We use a null entry that we can blend to or from when we do not have any curve.
			// This is in effect a flat line at the default value.
			Curves.Add(FBlendedCurve(nullptr, 1.0f));
		}

		// Note that this can be nullptr, in which case we want to blend back towards default value
		Curves.Add(FBlendedCurve(Curve, 0.f));
	}

	void SetTargetRuntimeCurve(FRuntimeFloatCurve Curve, float InBlendDuration)
	{
		if (InBlendDuration == 0.f)
		{
			// Snap target curve
			Curves.SetNum(1);
			Curves[0] = FBlendedCurve(Curve, 1.f);
			return;
		}

		BlendDuration = InBlendDuration;
		if ((Curves.Num() > 0) && (Curves[Curves.Num() - 1].RuntimeCurve.Equals(Curve)))
			return; // Already current
		
		if (Curves.Num() == 0)
		{
			// We use a null entry that we can blend to or from when we do not have any curve.
			// This is in effect a flat line at the default value.
			Curves.Add(FBlendedCurve(nullptr, 1.0f));
		}

		// Note that this can be nullptr, in which case we want to blend back towards default value
		Curves.Add(FBlendedCurve(Curve, 0.f));
	}

	void Update(float DeltaTime)
	{
		// Blend in last (current) curve
		if (Curves.Num() > 0)
			Curves[Curves.Num() - 1].Weight.AccelerateTo(1.f, BlendDuration, DeltaTime);

		// Blend out all other curves
		for (int i = Curves.Num() - 2; i >= 0; i--)
		{
			if (Curves[i].Weight.AccelerateTo(0.f, BlendDuration, DeltaTime) < 0.01f)
				Curves.RemoveAt(i);			
		}
	}

	float GetFloatValue(float Input) const
	{
		float TotalValue = 0.f;
		float TotalWeight = 0.f;
		for (FBlendedCurve BlendedCurve : Curves)
		{
			// Get value from curve with given input value. If curve is null, we use default value.
			float CurveValue = DefaultValue;
			if(BlendedCurve.bIsRuntimeFloatCurve)
			{
				CurveValue = BlendedCurve.RuntimeCurve.GetFloatValue(Input, DefaultValue);
			}
			else if (BlendedCurve.Curve != nullptr)
			{
				CurveValue = BlendedCurve.Curve.GetFloatValue(Input);
			}
				
			TotalValue += CurveValue * BlendedCurve.Weight.Value;
			TotalWeight += BlendedCurve.Weight.Value;
		}
		if (TotalWeight > 0.f)
			return TotalValue / TotalWeight;
		return DefaultValue;
	}

	bool NeedsUpdate(UCurveFloat Curve)
	{
		if (Curves.Num() > 1)
			return true;
		if (Curves.Last().bIsRuntimeFloatCurve)
			return true;
		if (Curves.Last().Curve != Curve)
			return true;
		return false;
	}

	bool NeedsUpdate(FRuntimeFloatCurve RuntimeCurve)
	{
		if (Curves.Num() > 1)
			return true;
		if (!Curves.Last().bIsRuntimeFloatCurve)
			return true;
		if (!Curves.Last().RuntimeCurve.Equals(RuntimeCurve))
			return true;
		return false;
	}
}
