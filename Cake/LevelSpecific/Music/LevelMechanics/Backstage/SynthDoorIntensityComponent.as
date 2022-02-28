import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SynthDoorStatics;

class USynthDoorIntensityComponent : UActorComponent
{
	int KickAmount = 0;
	int SnareAmount = 0;
	int CrashAmount = 0;
	
	ESynthDoorComponentIntensity CalculateDrumIntensity(int RowIndex, int RowPressedButtons, int TotalPressedButtons)
	{
		if (RowIndex == 0)
			KickAmount = RowPressedButtons;
		else if (RowIndex == 1)
			SnareAmount = RowPressedButtons;
		else if (RowIndex == 3)
			CrashAmount = RowPressedButtons;

		if (KickAmount > 6 || SnareAmount > 6 || CrashAmount > 5)
			return ESynthDoorComponentIntensity::High;
		else if (TotalPressedButtons > 26)
			return ESynthDoorComponentIntensity::High;
		else if (TotalPressedButtons > 9)
			return ESynthDoorComponentIntensity::Medium;
		else
			return ESynthDoorComponentIntensity::Low;
	}

	ESynthDoorComponentIntensity CalculateSynthIntensity(int RowIndex, int RowPressedButtons, int TotalPressedButtons)
	{
		if (TotalPressedButtons > 15)
			return ESynthDoorComponentIntensity::High;
		else if (TotalPressedButtons >= 6)
			return ESynthDoorComponentIntensity::Medium;
		else
			return ESynthDoorComponentIntensity::Low;
	}

	ESynthDoorComponentIntensity CalculateBassIntensity(int RowIndex, int RowPressedButtons, int TotalPressedButtons)
	{
		if (TotalPressedButtons >= 4)
			return ESynthDoorComponentIntensity::Medium;
		else
			return ESynthDoorComponentIntensity::Low;
	}
}