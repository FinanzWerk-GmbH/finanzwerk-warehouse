def update_service_display_name(cur, service_key, name):
    cur.execute(
        "UPDATE compliance.dim_service SET display_name = %s WHERE service_key = %s",
        (name, service_key),
    )


def update_vendor_risk_score(cur, vendor_id, new_score):
    cur.execute("""
        UPDATE vendors
        SET previous_risk_score = risk_score,
            risk_score = %s
        WHERE vendor_id = %s
    """, (new_score, vendor_id))


def update_config(cur, key, value, changed_by):
    # archive current value before overwriting, if one exists
    cur.execute("""
        INSERT INTO compliance.config_history (key, value, changed_by)
        SELECT key, value, %s FROM compliance.config_current WHERE key = %s
    """, (changed_by, key))
    cur.execute("""
        INSERT INTO compliance.config_current (key, value)
        VALUES (%s, %s)
        ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()
    """, (key, value))
