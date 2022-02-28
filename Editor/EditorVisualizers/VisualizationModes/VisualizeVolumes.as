import Vino.Checkpoints.Volumes.DeathVolume;

class UVisualizeVolumes
{
	bool IsVolumeOfType(UObject Object, UClass CheckClass) const
	{
		if (Object.IsA(CheckClass))
			return true;
		if (Object.Outer.IsA(CheckClass))
			return true;
		return false;
	}

    UFUNCTION()
    bool VisualizeDeathVolumes(UObject Object, FLinearColor& OutColor) const
    {
		if (IsVolumeOfType(Object, ADeathVolume::StaticClass()))
		{
			OutColor = FLinearColor(1.f, 0.f, 0.f, 1.f);
			return true;
		}
		else
		{
			OutColor = FLinearColor(1.f, 1.f, 1.f, 0.f);
			return true;
		}
    }
};