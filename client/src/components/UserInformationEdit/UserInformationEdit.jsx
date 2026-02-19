import { dequal } from 'dequal';
import omit from 'lodash/omit';
import React, { useCallback, useMemo, useRef } from 'react';
import PropTypes from 'prop-types';
import { useTranslation } from 'react-i18next';
import { Button, Dropdown, Form, Input } from 'semantic-ui-react';

import { useForm } from '../../hooks';

import styles from './UserInformationEdit.module.scss';

const SKILL_OPTIONS = [
  'Graphic Designer',
  'Video Editor',
  'Photographer',
  'Motion Designer',
  'Copywriter',
  'Social Media Manager',
  'Project Coordinator',
  'Data Analyst',
  'Developer',
  'Marketing Strategist',
].map((skill) => ({
  key: skill,
  value: skill,
  text: skill,
}));

const buildSkillOptions = (...skillGroups) => {
  const options = [...SKILL_OPTIONS];
  const existing = new Set(SKILL_OPTIONS.map((option) => option.value.toLowerCase()));

  skillGroups.forEach((skills) => {
    if (!Array.isArray(skills)) {
      return;
    }

    skills.forEach((skillValue) => {
      const skill = String(skillValue || '').trim();

      if (!skill) {
        return;
      }

      const key = skill.toLowerCase();

      if (existing.has(key)) {
        return;
      }

      existing.add(key);
      options.push({
        key: `custom-${key}`,
        value: skill,
        text: skill,
      });
    });
  });

  return options;
};

const normalizeSkills = (skills) => {
  if (!Array.isArray(skills)) {
    return [];
  }

  const unique = new Set();

  return skills.reduce((result, skillValue) => {
    const skill = String(skillValue || '').trim();

    if (!skill) {
      return result;
    }

    const key = skill.toLowerCase();

    if (unique.has(key)) {
      return result;
    }

    unique.add(key);
    result.push(skill);

    return result;
  }, []);
};

const UserInformationEdit = React.memo(({ defaultData, isNameEditable, onUpdate }) => {
  const [t] = useTranslation();

  const normalizedDefaultData = useMemo(
    () => ({
      name: defaultData.name || '',
      phone: defaultData.phone || null,
      organization: defaultData.organization || null,
      skills: normalizeSkills(defaultData.skills),
    }),
    [defaultData],
  );

  const [data, handleFieldChange] = useForm(() => ({
    name: normalizedDefaultData.name,
    phone: normalizedDefaultData.phone || '',
    organization: normalizedDefaultData.organization || '',
    skills: normalizedDefaultData.skills,
  }));

  const cleanData = useMemo(
    () => ({
      name: data.name.trim(),
      phone: data.phone.trim() || null,
      organization: data.organization.trim() || null,
      skills: normalizeSkills(data.skills),
    }),
    [data],
  );

  const skillOptions = useMemo(
    () => buildSkillOptions(normalizedDefaultData.skills, data.skills),
    [normalizedDefaultData.skills, data.skills],
  );

  const nameField = useRef(null);

  const handleSkillsChange = useCallback(
    (_, { value }) => {
      handleFieldChange(null, {
        name: 'skills',
        value: normalizeSkills(value),
      });
    },
    [handleFieldChange],
  );

  const handleSubmit = useCallback(() => {
    if (isNameEditable) {
      if (!cleanData.name) {
        nameField.current.select();
        return;
      }

      onUpdate(cleanData);
    } else {
      onUpdate(omit(cleanData, 'name'));
    }
  }, [isNameEditable, onUpdate, cleanData]);

  return (
    <Form onSubmit={handleSubmit}>
      <div className={styles.text}>{t('common.name')}</div>
      <Input
        fluid
        ref={nameField}
        name="name"
        value={data.name}
        disabled={!isNameEditable}
        className={styles.field}
        onChange={handleFieldChange}
      />
      <div className={styles.text}>{t('common.phone')}</div>
      <Input
        fluid
        name="phone"
        value={data.phone}
        className={styles.field}
        onChange={handleFieldChange}
      />
      <div className={styles.text}>{t('common.organization')}</div>
      <Input
        fluid
        name="organization"
        value={data.organization}
        className={styles.field}
        onChange={handleFieldChange}
      />
      <div className={styles.text}>{t('common.skills')}</div>
      <Dropdown
        fluid
        multiple
        search
        selection
        allowAdditions
        name="skills"
        options={skillOptions}
        value={data.skills}
        placeholder={t('common.addSkillsPlaceholder')}
        className={styles.field}
        onChange={handleSkillsChange}
      />
      <Button
        positive
        disabled={dequal(cleanData, normalizedDefaultData)}
        content={t('action.save')}
      />
    </Form>
  );
});

UserInformationEdit.propTypes = {
  defaultData: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  isNameEditable: PropTypes.bool.isRequired,
  onUpdate: PropTypes.func.isRequired,
};

export default UserInformationEdit;
